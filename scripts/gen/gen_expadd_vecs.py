"""Generate CSV test vectors for the SystemVerilog `fmaexpadd` module.

The DUT interface (from expadd.sv):
    module fmaexpadd(
        input  logic [4:0]  Xe,
        input  logic [4:0]  Ye,
        input  logic        XZero,
        input  logic        YZero,
        output logic [10:0] Pe,
        output logic        PeOverflow
    );

We reproduce the combinational logic in Python to create a golden reference.

CSV Columns (header):
    Xe,Ye,XZero,YZero,Pe,PeOverflow

All numeric fields are emitted as unsigned integers (base 10).

Usage (PowerShell examples):
    # Default: 1024 mixed values -> expadd_vectors.csv
    python gen_expadd_vecs.py

    # Custom count and output file
    python gen_expadd_vecs.py --count 5000 --out my_vectors.csv

    # Deterministic (default seed=54321) or choose your own
    python gen_expadd_vecs.py --seed 42

The script purposely includes edge cases (zeros, underflows, overflows, 
boundary exponents) before filling remaining slots with random values.
"""

from __future__ import annotations

import argparse
import csv
import random
from typing import Iterable, List, Sequence, Tuple


def expadd_reference(xe: int, ye: int, xzero: int, yzero: int) -> dict:
    """Return a dictionary of expected output signals for exponent addition.

    Mirrors the RTL equations in `expadd.sv`.

    Args:
        xe: 5-bit exponent of X (0..31)
        ye: 5-bit exponent of Y (0..31)
        xzero: 1 if X is zero
        yzero: 1 if Y is zero
    Returns:
        dict with keys: Pe, PeOverflow
    """
    xe &= 0x1F
    ye &= 0x1F
    xzero &= 0x1
    yzero &= 0x1

    # Exponent addition with bias subtraction
    # Half-precision bias = 15
    exp_sum = xe + ye - 15

    # Handle zero inputs
    if xzero or yzero:
        pe = 0
        pe_overflow = 0
    elif exp_sum > 30:
        pe = 31  # Set to max exponent (infinity)
        pe_overflow = 1
    else:
        # exp_sum is 6-bit signed in RTL, but we check > 30
        # For negative results (underflow), RTL will wrap but logic should handle
        if exp_sum < 0:
            pe = 0
            pe_overflow = 0
        else:
            pe = exp_sum & 0x1F  # Take lower 5 bits
            pe_overflow = 0

    # Pe is 11-bit in RTL but only lower 5-6 bits are used
    # RTL assigns Pe = {1'b0, exp_sum[4:0]} in normal case
    # So Pe will be 0-padded to 11 bits
    return {
        "Pe": pe & 0x7FF,  # 11-bit value
        "PeOverflow": pe_overflow,
    }


HEADER = [
    "Xe_hex",
    "Ye_hex", 
    "XZero",
    "YZero",
    "Pe_hex",
    "PeOverflow",
]


def canonical_edge_cases() -> List[Tuple[int, int, int, int]]:
    """Return curated list of (Xe, Ye, XZero, YZero) tuples hitting edge cases."""
    cases = []
    
    # Both zeros
    cases.append((0, 0, 1, 1))
    cases.append((15, 15, 1, 1))
    
    # X zero, Y non-zero
    cases.append((0, 0, 1, 0))
    cases.append((0, 15, 1, 0))
    cases.append((0, 31, 1, 0))
    
    # Y zero, X non-zero
    cases.append((0, 0, 0, 1))
    cases.append((15, 0, 0, 1))
    cases.append((31, 0, 0, 1))
    
    # Both non-zero: Normal cases around bias
    # Xe=15, Ye=15 -> exp_sum = 15+15-15 = 15 (normal)
    cases.append((15, 15, 0, 0))
    
    # Small exponents (underflow territory)
    cases.append((1, 1, 0, 0))    # 1+1-15 = -13 -> underflow
    cases.append((1, 15, 0, 0))   # 1+15-15 = 1 (small normal)
    cases.append((0, 15, 0, 0))   # 0+15-15 = 0 (subnormal territory)
    cases.append((15, 0, 0, 0))   # 15+0-15 = 0 (subnormal)
    
    # Overflow cases
    cases.append((31, 31, 0, 0))  # 31+31-15 = 47 > 30 -> overflow
    cases.append((20, 20, 0, 0))  # 20+20-15 = 25 (normal)
    cases.append((16, 16, 0, 0))  # 16+16-15 = 17 (normal)
    cases.append((30, 30, 0, 0))  # 30+30-15 = 45 > 30 -> overflow
    cases.append((16, 15, 0, 0))  # 16+15-15 = 16 (normal)
    cases.append((20, 11, 0, 0))  # 20+11-15 = 16 (normal)
    
    # Boundary: exactly exp_sum = 30 (max normal)
    cases.append((15, 30, 0, 0))  # 15+30-15 = 30 (max finite)
    cases.append((22, 23, 0, 0))  # 22+23-15 = 30 (max finite)
    
    # Boundary: exp_sum = 31 (just over)
    cases.append((16, 30, 0, 0))  # 16+30-15 = 31 > 30 -> overflow
    cases.append((23, 23, 0, 0))  # 23+23-15 = 31 > 30 -> overflow
    
    # Max exponent inputs (infinity/NaN territory in FP, but expadd just adds)
    cases.append((31, 0, 0, 0))   # 31+0-15 = 16
    cases.append((0, 31, 0, 0))   # 0+31-15 = 16
    cases.append((31, 1, 0, 0))   # 31+1-15 = 17
    cases.append((1, 31, 0, 0))   # 1+31-15 = 17
    cases.append((31, 15, 0, 0))  # 31+15-15 = 31 > 30 -> overflow
    cases.append((15, 31, 0, 0))  # 15+31-15 = 31 > 30 -> overflow
    
    return cases


def fill_random_cases(
    existing: Sequence[Tuple[int, int, int, int]], 
    target_count: int, 
    seed: int
) -> List[Tuple[int, int, int, int]]:
    """Fill remaining slots with random test cases."""
    if len(existing) >= target_count:
        return list(existing)[:target_count]
    
    random.seed(seed)
    result = list(existing)
    seen = set(result)
    
    while len(result) < target_count:
        # Generate random 5-bit exponents and zero flags
        xe = random.randrange(0, 32)
        ye = random.randrange(0, 32)
        # Bias toward non-zero (90% chance each is non-zero)
        xzero = 1 if random.random() < 0.1 else 0
        yzero = 1 if random.random() < 0.1 else 0
        
        case = (xe, ye, xzero, yzero)
        if case not in seen:
            seen.add(case)
            result.append(case)
    
    return result


def generate_expadd_csv(
    out_path: str = "expadd_vectors.csv",
    *,
    cases: Iterable[Tuple[int, int, int, int]] | None = None,
    count: int = 1024,
    seed: int = 54321,
    include_header: bool = True,
) -> List[Tuple[int, int, int, int]]:
    """Generate a CSV of test vectors for the fmaexpadd module.

    Args:
        out_path: Output CSV filename.
        cases: Optional iterable of explicit (Xe, Ye, XZero, YZero) tuples.
        count: Total number of rows to emit (pad with random if needed).
        seed: RNG seed for random fill.
        include_header: Whether to write CSV header.
    Returns:
        The ordered list of test cases written.
    """
    if cases is not None:
        base = list(cases)
    else:
        base = canonical_edge_cases()
    
    all_cases = fill_random_cases(base, count, seed)

    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f)
        if include_header:
            writer.writerow(HEADER)
        
        for xe, ye, xzero, yzero in all_cases:
            ref = expadd_reference(xe, ye, xzero, yzero)
            row = [
                f"0x{xe:02X}",
                f"0x{ye:02X}",
                xzero,
                yzero,
                f"0x{ref['Pe']:03X}",  # 11-bit value up to 0x7FF
                ref["PeOverflow"],
            ]
            writer.writerow(row)
    
    return all_cases


def parse_explicit_cases(arg: str) -> List[Tuple[int, int, int, int]]:
    """Parse explicit test cases from command line.
    
    Format: Xe:Ye:XZero:YZero,Xe:Ye:XZero:YZero,...
    Example: 15:15:0:0,31:31:0:0
    """
    cases: List[Tuple[int, int, int, int]] = []
    for piece in arg.split(','):
        piece = piece.strip()
        if not piece:
            continue
        parts = piece.split(':')
        if len(parts) != 4:
            raise argparse.ArgumentTypeError(
                f"Invalid case '{piece}': expected format Xe:Ye:XZero:YZero"
            )
        try:
            xe, ye, xzero, yzero = [int(p) for p in parts]
            if not (0 <= xe < 32 and 0 <= ye < 32 and xzero in (0, 1) and yzero in (0, 1)):
                raise ValueError("Out of range")
            cases.append((xe, ye, xzero, yzero))
        except ValueError as e:
            raise argparse.ArgumentTypeError(
                f"Invalid case '{piece}': {e}"
            )
    return cases


def main(argv: Sequence[str] | None = None) -> None:
    p = argparse.ArgumentParser(
        description="Generate CSV test vectors for fmaexpadd module"
    )
    p.add_argument(
        '--out', '-o', 
        default='tb/vecs/expadd_vectors.csv',
        help='Output CSV filename'
    )
    p.add_argument(
        '--count', '-n', 
        type=int, 
        default=1024,
        help='Total number of vectors to emit (default 1024)'
    )
    p.add_argument(
        '--seed', 
        type=int, 
        default=54321,
        help='RNG seed for random generation'
    )
    p.add_argument(
        '--cases',
        type=str,
        help='Comma-separated explicit cases in format Xe:Ye:XZero:YZero (replaces curated edge list)'
    )
    p.add_argument(
        '--no-header', 
        action='store_true',
        help='Omit CSV header row'
    )
    args = p.parse_args(argv)

    explicit = parse_explicit_cases(args.cases) if args.cases else None
    used = generate_expadd_csv(
        args.out,
        cases=explicit,
        count=args.count,
        seed=args.seed,
        include_header=not args.no_header,
    )
    
    print(f"Wrote {len(used)} vectors to {args.out}")
    print(f"First 8 cases:")
    for i, (xe, ye, xz, yz) in enumerate(used[:8]):
        ref = expadd_reference(xe, ye, xz, yz)
        print(f"  {i+1}. Xe=0x{xe:02X} Ye=0x{ye:02X} XZero={xz} YZero={yz} -> "
              f"Pe=0x{ref['Pe']:03X} PeOverflow={ref['PeOverflow']}")


if __name__ == '__main__':  # pragma: no cover - CLI entry
    main()
