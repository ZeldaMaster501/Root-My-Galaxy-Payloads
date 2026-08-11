#ifndef E3Q_S928USQS6DZG1_TARGET_H
#define E3Q_S928USQS6DZG1_TARGET_H

/*
 * DZG1 retains the DZF2 symbol addresses and complete BTF layout exactly.
 * Keep that shared, audited constant set explicit while using DZG1's distinct
 * physical-page fingerprint below.
 */
#include "../e3q-S928USQS6DZF2/target.h"

#undef BUILD_VARIANT_LABEL
#if defined(APP_PAYLOAD) && APP_PAYLOAD
#define BUILD_VARIANT_LABEL "e3q-S928USQS6DZG1-app-physical-p0-oracle"
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
