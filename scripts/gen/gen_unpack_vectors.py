"""Generate CSV test vectors for the SystemVerilog `unpack` module.

The DUT interface (from unpack.sv):
    module unpack(
        input  logic [15:0] X,
        output logic        SgnX,
        output logic [4:0]  ExpX,
        output logic [10:0] ManX,
        output logic        XNaN,
        output logic        XSNaN,
        output logic        XZero,
        output logic        XInf,       # NOTE: not currently assigned in RTL!
        output logic        XExpMax,
        output logic        XSubnorm
    );

We reproduce the combinational logic in Python to create a golden reference.

CSV Columns (header):
    X_hex,SgnX,ExpX,ManX,XNaN,XSNaN,XZero,XInf,XExpMax,XSubnorm

All numeric fields besides X_hex are emitted as unsigned integers (base 10).

Usage (PowerShell examples):
    # Default: 1024 mixed values -> unpack_vectors.csv
    python gen_unpack_vectors.py

    # Custom count and output file
    python gen_unpack_vectors.py --count 5000 --out my_vectors.csv

    # Deterministic (default seed=12345) or choose your own
    python gen_unpack_vectors.py --seed 42

You can limit to specific explicit hex values:
    python gen_unpack_vectors.py --values 3C00,BC00,7C00

The script purposely includes edge cases (zeros, subnormals, normals near
boundaries, infinities, signaling & quiet NaNs) before filling remaining
slots with random values.
"""

from __future__ import annotations

import argparse
import csv
import random
from typing import Iterable, List, Sequence


def unpack_reference(x: int) -> dict:
    """Return a dictionary of expected output signals for a 16-bit half.

    Mirrors the RTL equations in `unpack.sv` (plus XInf which is missing there).

    Args:
        x: 0..65535 raw 16-bit pattern.
    Returns:
        dict with keys matching CSV header (except X_hex which caller adds).
    """
    x &= 0xFFFF
    sgn = (x >> 15) & 0x1
    exp = (x >> 10) & 0x1F  # 5 bits
    frac = x & 0x3FF        # 10 bits

    exp_non_zero = 1 if exp != 0 else 0
    man = (exp_non_zero << 10) | frac  # 11 bits
    exp_max = 1 if exp == 0x1F else 0
    frac_zero = 1 if frac == 0 else 0
    x_nan = 1 if (exp_max and not frac_zero) else 0
    x_snan = 1 if (x_nan and ((frac >> 9) & 0x1)) else 0  # MSB of frac
    x_zero = 1 if ((not exp_non_zero) and frac_zero) else 0
    x_subnorm = 1 if ((not exp_non_zero) and (not frac_zero)) else 0
    x_inf = 1 if (exp_max and frac_zero) else 0  # (Missing assign in RTL!)

    return {
        "SgnX": sgn,
        "ExpX": exp,
        "ManX": man,
        "XNaN": x_nan,
        "XSNaN": x_snan,
        "XZero": x_zero,
        "XInf": x_inf,
        "XExpMax": exp_max,
        "XSubnorm": x_subnorm,
    }


HEADER = [
    "X_hex",
    "SgnX",
    "ExpX",
    "ManX",
    "XNaN",
    "XSNaN",
    "XZero",
    "XInf",
    "XExpMax",
    "XSubnorm",
]


def canonical_edge_values() -> List[int]:
    """Return a curated list of half-precision patterns hitting edge cases."""
    vals = []
    # Zeros
    vals += [0x0000, 0x8000]  # +0, -0
    # Smallest subnormals (LSB set) and a mid subnormal, largest subnormal
    vals += [0x0001, 0x0400, 0x03FF, 0x83FF]
    # Smallest normal (exp=1, frac=0) both signs
    vals += [0x0400, 0x8400]
    # 1.0 (exp=0x0F? Wait half: exponent bias=15 => 1.0 = exp=15 (0x0F), frac=0)
    vals += [0x3C00, 0xBC00]
    # Max finite normal (exp=0x1E, frac all ones)
    vals += [0x7BFF, 0xFBFF]
    # Infinities
    vals += [0x7C00, 0xFC00]
    # Signaling NaN (MSB of frac =1 for SNaN per RTL: frac[9]==1). Choose pattern with bit9=1 and others 0.
    vals += [0x7E00, 0xFE00]
    # Quiet NaN example (bit9=0 but some other frac bit set)
    vals += [0x7D00, 0xFD00]
    return list(dict.fromkeys(vals))  # dedupe while preserving order


def fill_random(existing: Sequence[int], target_count: int, seed: int) -> List[int]:
    if len(existing) >= target_count:
        return list(existing)[:target_count]
    random.seed(seed)
    result = list(existing)
    seen = set(result)
    while len(result) < target_count:
        v = random.randrange(0, 1 << 16)
        if v not in seen:
            seen.add(v)
            result.append(v)
    return result


def generate_unpack_csv(
    out_path: str = "unpack_vectors.csv",
    *,
    values: Iterable[int] | None = None,
    count: int = 1024,
    seed: int = 12345,
    include_header: bool = True,
) -> List[int]:
    """Generate a CSV of test vectors for the unpack module.

    Args:
        out_path: Output CSV filename.
        values: Optional iterable of explicit integer patterns to use.
        count: Total number of rows to emit (pad with random if needed).
        seed: RNG seed for random fill.
        include_header: Whether to write CSV header.
    Returns:
        The ordered list of 16-bit values written.
    """
    if values is not None:
        base = list(values)
    else:
        base = canonical_edge_values()
    all_vals = fill_random(base, count, seed)

    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f)
        if include_header:
            writer.writerow(HEADER)
        for x in all_vals:
            ref = unpack_reference(x)
            row = [
                f"0x{x:04X}",
                ref["SgnX"],
                ref["ExpX"],
                ref["ManX"],
                ref["XNaN"],
                ref["XSNaN"],
                ref["XZero"],
                ref["XInf"],
                ref["XExpMax"],
                ref["XSubnorm"],
            ]
            writer.writerow(row)
    return all_vals


def parse_explicit_values(arg: str) -> List[int]:
    vals: List[int] = []
    for piece in arg.split(','):
        piece = piece.strip()
        if not piece:
            continue
        if piece.lower().startswith('0x'):
            vals.append(int(piece, 16))
        else:
            # Accept plain hex (e.g. 3C00) or decimal
            try:
                vals.append(int(piece, 16) if all(c in '0123456789abcdefABCDEF' for c in piece) else int(piece, 10))
            except ValueError as e:
                raise argparse.ArgumentTypeError(f"Invalid value '{piece}': {e}")
    return vals


def main(argv: Sequence[str] | None = None) -> None:
    p = argparse.ArgumentParser(description="Generate CSV test vectors for unpack module")
    p.add_argument('--out', '-o', default='../../tb/vecs/unpack_vectors.csv', help='Output CSV filename')
    p.add_argument('--count', '-n', type=int, default=1024, help='Total number of vectors to emit (default 1024)')
    p.add_argument('--seed', type=int, default=12345, help='RNG seed for random generation')
    p.add_argument('--values', type=str, help='Comma-separated explicit hex/dec values (replaces curated edge list)')
    p.add_argument('--no-header', action='store_true', help='Omit CSV header row')
    args = p.parse_args(argv)

    explicit = parse_explicit_values(args.values) if args.values else None
    used = generate_unpack_csv(
        args.out,
        values=explicit,
        count=args.count,
        seed=args.seed,
        include_header=not args.no_header,
    )
    print(f"Wrote {len(used)} vectors to {args.out}")
    print("First 8 values:", ' '.join(f"0x{v:04X}" for v in used[:8]))


if __name__ == '__main__':  # pragma: no cover - CLI entry
    main()
