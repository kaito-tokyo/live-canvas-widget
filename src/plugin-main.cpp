// SPDX-FileCopyrightText: 2026 Kaito Udagawa <umireon@kaito.tokyo>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include <obs-module.h>

#include "plugin-support.hpp"

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE(PLUGIN_NAME, "en-US")

bool obs_module_load() {
  logInfo("[" PLUGIN_NAME "] plugin loaded successfully (version " PLUGIN_VERSION ")");
  return true;
}

void obs_module_unload() { logInfo("[%s] plugin unloaded", PLUGIN_NAME); }
