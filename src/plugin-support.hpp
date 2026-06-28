// SPDX-FileCopyrightText: 2026 Kaito Udagawa <umireon@kaito.tokyo>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <utility>

#ifndef PLUGIN_NAME
#define PLUGIN_NAME "live-canvas-widget"
#endif

#ifndef PLUGIN_VERSION
#define PLUGIN_VERSION "0.0.0"
#endif

#ifndef PLUGIN_VERSION_SUFFIX
#define PLUGIN_VERSION_SUFFIX "-SNAPSHOT"
#endif

extern "C" void blog(int log_level, const char *format, ...);

inline void logError(const char *fmt) noexcept { blog(100, "%s", fmt); }

inline void logWarning(const char *fmt) noexcept { blog(200, "%s", fmt); }

inline void logInfo(const char *fmt) noexcept { blog(300, "%s", fmt); }

inline void logDebug(const char *fmt) noexcept { blog(400, "%s", fmt); }

template <typename... Args> void logError(const char *fmt, Args &&...args) noexcept {
  blog(100, fmt, std::forward<Args>(args)...);
}

template <typename... Args> void logWarning(const char *fmt, Args &&...args) noexcept {
  blog(200, fmt, std::forward<Args>(args)...);
}

template <typename... Args> void logInfo(const char *fmt, Args &&...args) noexcept {
  blog(300, fmt, std::forward<Args>(args)...);
}

template <typename... Args> void logDebug(const char *fmt, Args &&...args) noexcept {
  blog(400, fmt, std::forward<Args>(args)...);
}
