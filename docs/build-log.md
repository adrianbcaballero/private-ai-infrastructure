# Build Log

## Hardware Sourcing
Core components were sourced second-hand via Facebook Marketplace
to keep build cost low while still landing dual-GPU capacity for
local inference. The trade-off: unknown component history meant
stability validation mattered before trusting the box with
persistent workloads.

## Challenges and Solutions

### Boot sequence loop
Initial boots looped at POST without reaching the bootloader.
Diagnosis took several passes of component isolation — drives
disconnected, single GPU installed, single RAM stick at a time —
to narrow the fault from "system" down to "one specific
component."

Root cause: one of the DDR4 sticks was dead. Not salvageable —
discarded it and ran on the remaining stick(s). System POSTed
cleanly on the next boot and has been stable since.

### Dual GPU tensor split tuning
llama.cpp with CUDA needed deliberate layer distribution across
the GTX 1080 (8GB) and GTX 1660 Super (6GB) — naive splits
oversubscribed the smaller card. Settled on a tensor-split ratio
weighted toward the 1080 to keep the 1660 below its VRAM ceiling
under sustained load.

## Lessons Learned
- Component-isolation diagnosis is faster than swapping
  wholesale when you don't have known-good spares on hand.
- Second-hand hardware is fine for self-hosted infrastructure,
  but budget time for stability validation — don't treat it as
  production on day one.
- Keep a written change log during a long debug session. By the
  third reseat I had forgotten which configurations I had
  already ruled out.
- Asymmetric multi-GPU setups need explicit tuning. Defaults
  assume matched cards.
