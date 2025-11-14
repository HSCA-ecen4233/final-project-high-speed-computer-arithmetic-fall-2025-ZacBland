"""Generate CSV test vectors for current `align` module (FP16 FMA stage).

RTL (align.sv) summary:
    exp_diff = Xe - Ye (5-bit subtraction, wraps if Xe < Ye)
    if exp_diff >= 10:
        Am = 0
        ASticky = OR of all bits of Zm
    else:
        Am = Zm >> exp_diff
        ASticky = OR of discarded lower exp_diff bits of Zm
    KillProd = XZero | YZero | ZZero

IMPORTANT: Because exp_diff is a 5-bit result, when Xe < Ye the subtraction
wraps around (e.g. 5 - 10 -> 0x1B = 27) causing large shifts (>=10) and thus
Am=0, sticky set to any Zm bit. If you INTEND no alignment when Xe < Ye, you
should fix RTL to use: exp_diff = (Xe > Ye) ? Xe-Ye : 5'd0.

This generator defaults to matching the CURRENT RTL wrap behavior. Pass
--intended to treat negative differences as 0 (intended semantics).

CSV Columns:
    Ze_hex,Zm_hex,XZero,YZero,ZZero,Xe_hex,Ye_hex,Am_hex,ASticky,KillProd

Usage (PowerShell):
    python scripts/gen/gen_align_vectors.py
    python scripts/gen/gen_align_vectors.py --count 2048 --out tb/vecs/align_vectors.csv
    python scripts/gen/gen_align_vectors.py --seed 42 --intended
    python scripts/gen/gen_align_vectors.py --cases "15:3FF:0:0:0:16:15,10:2AA:0:0:0:15:11"

"""

from __future__ import annotations

import argparse
import csv
import random
from typing import Iterable, List, Sequence, Tuple

HEADER = [
    "Ze_hex","Zm_hex","XZero","YZero","ZZero","Xe_hex","Ye_hex","Am_hex","ASticky","KillProd"
]

def rtl_align(zm: int, xe: int, ye: int, xzero: int, yzero: int, zzero: int, *, intended: bool=False):
    """Replicate align.sv behavior.

    Args:
        zm, xe, ye: mantissa (10 bits) and exponents (5 bits)
        xzero,yzero,zzero: zero flags (0/1)
        intended: if True, treat exp_diff negative as 0; else wrap 5-bit.
    Returns: (Am, ASticky, KillProd)
    """
    zm &= 0x3FF
    xe &= 0x1F
    ye &= 0x1F
    xzero &= 1; yzero &= 1; zzero &= 1

    if intended:
        exp_diff = xe - ye if xe > ye else 0
    else:
        # 5-bit wrap behavior
        exp_diff = (xe - ye) & 0x1F

    if exp_diff >= 10:
        am = 0
        asticky = 1 if zm != 0 else 0
    else:
        am = zm >> exp_diff
        if exp_diff == 0:
            asticky = 0
        else:
            mask = (1 << exp_diff) - 1
            asticky = 1 if (zm & mask) != 0 else 0

    kill = xzero | yzero | zzero
    return am, asticky, kill


def edge_cases() -> List[Tuple[int,int,int,int,int,int,int]]:
    cases = []
    # Format: (Ze, Zm, XZero, YZero, ZZero, Xe, Ye)
    cases += [
        (15, 0x000, 0,0,0, 15,15),   # no shift, zero mantissa
        (15, 0x3FF, 0,0,0, 16,15),   # small shift (1)
        (15, 0x3FF, 0,0,0, 20,15),   # larger shift (<10)
        (15, 0x3FF, 0,0,0, 26,15),   # exp_diff=11 wrap scenario
        (15, 0x155, 0,0,0, 5,10),    # Xe<Ye wrap, sticky from all bits if >=10 when wrapped
        (15, 0x001, 0,0,0, 5,10),
        (15, 0x200, 1,0,0, 16,15),   # XZero affects kill
        (15, 0x200, 0,1,0, 16,15),   # YZero
        (15, 0x200, 0,0,1, 16,15),   # ZZero
        (0 , 0x2AA, 0,0,0, 31,0),    # big diff potential
        (31,0x2AA, 0,0,0, 31,0),     # diff=31 wrap
        (5 ,0x3FF, 0,0,0, 15,5),     # diff=10 boundary
    ]
    return cases


def fill_random(existing: Sequence[Tuple[int,int,int,int,int,int,int]], target: int, seed: int) -> List[Tuple[int,int,int,int,int,int,int]]:
    if len(existing) >= target:
        return list(existing)[:target]
    random.seed(seed)
    out = list(existing)
    seen = set(out)
    while len(out) < target:
        ze = random.randrange(0,32)
        zm = random.randrange(0,1024)
        xe = random.randrange(0,32)
        ye = random.randrange(0,32)
        xz = 1 if random.random() < 0.05 else 0
        yz = 1 if random.random() < 0.05 else 0
        zz = 1 if random.random() < 0.05 else 0
        tpl = (ze, zm, xz, yz, zz, xe, ye)
        if tpl not in seen:
            seen.add(tpl)
            out.append(tpl)
    return out


def generate_csv(out_path: str, *, count: int, seed: int, intended: bool, include_header: bool=True) -> List[Tuple[int,int,int,int,int,int,int]]:
    base = edge_cases()
    all_cases = fill_random(base, count, seed)
    with open(out_path, 'w', newline='') as f:
        w = csv.writer(f)
        if include_header:
            w.writerow(HEADER)
        for ze, zm, xz, yz, zz, xe, ye in all_cases:
            am, asticky, kill = rtl_align(zm, xe, ye, xz, yz, zz, intended=intended)
            w.writerow([
                f"0x{ze:02X}", f"0x{zm:03X}", xz, yz, zz,
                f"0x{xe:02X}", f"0x{ye:02X}", f"0x{am:03X}", asticky, kill
            ])
    return all_cases


def parse_cases(arg: str) -> List[Tuple[int,int,int,int,int,int,int]]:
    cases: List[Tuple[int,int,int,int,int,int,int]] = []
    for piece in arg.split(','):
        piece = piece.strip()
        if not piece: continue
        parts = piece.split(':')
        if len(parts) != 7:
            raise argparse.ArgumentTypeError(f"Case '{piece}' must have 7 fields: Ze:Zm:XZero:YZero:ZZero:Xe:Ye")
        vals = []
        for p in parts:
            if p.lower().startswith('0x'): vals.append(int(p,16))
            else: vals.append(int(p))
        ze, zm, xz, yz, zz, xe, ye = vals
        if not (0<=ze<32 and 0<=zm<1024 and xz in (0,1) and yz in (0,1) and zz in (0,1) and 0<=xe<32 and 0<=ye<32):
            raise argparse.ArgumentTypeError(f"Values out of range in '{piece}'")
        cases.append((ze, zm, xz, yz, zz, xe, ye))
    return cases


def main(argv: Sequence[str] | None = None) -> None:
    p = argparse.ArgumentParser(description="Generate CSV test vectors for current align module")
    p.add_argument('--out','-o', default='tb/vecs/align_vectors.csv', help='Output CSV path')
    p.add_argument('--count','-n', type=int, default=1024, help='Total rows (default 1024)')
    p.add_argument('--seed', type=int, default=98765, help='RNG seed')
    p.add_argument('--cases', type=str, help='Explicit cases Ze:Zm:XZero:YZero:ZZero:Xe:Ye comma-separated')
    p.add_argument('--no-header', action='store_true', help='Omit header row')
    p.add_argument('--intended', action='store_true', help='Use intended non-wrapping exp_diff semantics')
    args = p.parse_args(argv)

    if args.cases:
        base = parse_cases(args.cases)
        # Repack into full tuples adding dummy mantissa of same pattern? We'll treat provided list as base cases
        all_cases = fill_random(base, args.count, args.seed)
    else:
        all_cases = fill_random(edge_cases(), args.count, args.seed)

    # Generate using final list (edge/random). We recompute again for output to maintain order.
    generated = generate_csv(args.out, count=args.count, seed=args.seed, intended=args.intended, include_header=not args.no_header)
    print(f"Wrote {len(generated)} vectors to {args.out}")
    print("First 6 preview:")
    for i,(ze,zm,xz,yz,zz,xe,ye) in enumerate(generated[:6]):
        am, asticky, kill = rtl_align(zm, xe, ye, xz, yz, zz, intended=args.intended)
        print(f"  {i+1}. Ze=0x{ze:02X} Zm=0x{zm:03X} Xe=0x{xe:02X} Ye=0x{ye:02X} Zeros={xz}{yz}{zz} -> Am=0x{am:03X} Sticky={asticky} Kill={kill}")


if __name__ == '__main__':  # pragma: no cover
    main()
