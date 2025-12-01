# ================================================================
# PDP/EDP Computation Utilities
# Authors: Ryan Swann and James E. Stine
# Description:
#     Engineering-notation utilities and detailed power-delay
#     calculations, including PDP (Power–Delay Product) and
#     EDP (Energy–Delay Product) with verbose step-by-step output.
# ================================================================

def eng(x, unit=""):
    import math
    if x == 0:
        return f"0 {unit}"
    exp = int(math.floor(math.log10(abs(x)) / 3) * 3)
    mant = x / (10**exp)
    return f"{mant:.6g}e{exp} {unit}"

def compute_pdp_edp_verbose(P, d):
    """
    P : power in watts (scientific notation allowed)
    d : delay in seconds (scientific notation allowed)
    """

    print("=== INPUTS ===")
    print(f"P (power): {eng(P, 'W')}")
    print(f"d (delay): {eng(d, 's')}\n")

    # ------------------------------
    # 1. Compute PDP = P * d
    # ------------------------------
    print("=== STEP 1: Compute PDP = P * d ===")

    pdp = P * d
    print(f"PDP = {eng(P)} * {eng(d)}")
    print(f"PDP = {eng(pdp, 'J')}   (W·s = J)\n")

    # Convert PDP to pJ
    pdp_pj = pdp * 1e12
    print("Convert PDP to pJ:")
    print("1 pJ = 1e-12 J → multiply J by 1e12 to get pJ")
    print(f"PDP_pJ = {eng(pdp)} * 1e12 = {eng(pdp_pj, 'pJ')}\n")

    # ------------------------------
    # 2. Compute EDP = PDP * d
    # ------------------------------
    print("=== STEP 2: Compute EDP = PDP * d ===")

    edp = pdp * d
    print(f"EDP = {eng(pdp)} * {eng(d)}")
    print(f"EDP = {eng(edp, 'J·s')}   (energy × delay)\n")

    # ------------------------------
    # 3. Show EDP as J/Hz
    # ------------------------------
    print("=== STEP 3: Convert EDP to J/Hz ===")
    print("Since 1 Hz = 1/s → 1/Hz = s,")
    print("J·s and J/Hz are the SAME UNIT.")
    print(f"EDP = {eng(edp, 'J/Hz')}\n")

    # ------------------------------
    # 4. Convert EDP to pJ/GHz
    # ------------------------------
    print("=== STEP 4: Convert EDP to pJ/GHz ===")
    print("We use the identity:")
    print("   1 pJ/GHz = 10^-21 J·s")
    print("So to convert J·s → pJ/GHz, multiply by 1e21.")

    edp_pj_per_ghz = edp * 1e21
    print(f"EDP_pJ_per_GHz = {eng(edp)} * 1e21")
    print(f"EDP_pJ_per_GHz = {eng(edp_pj_per_ghz, 'pJ/GHz')}\n")

    # ------------------------------
    # 5. Final summary
    # ------------------------------
    print("=== SUMMARY ===")
    print(f"PDP: {eng(pdp, 'J')}   = {eng(pdp_pj, 'pJ')}")
    print(f"EDP: {eng(edp, 'J·s')} = {eng(edp_pj_per_ghz, 'pJ/GHz')}")



# ===============================
# P = 5.804 mW, d = 1.784334 ns
# ===============================

compute_pdp_edp_verbose(
    P = 5.804e-3,        # 5.804 mW
    d = 1.784334e-9      # 1.784334 ns
)
