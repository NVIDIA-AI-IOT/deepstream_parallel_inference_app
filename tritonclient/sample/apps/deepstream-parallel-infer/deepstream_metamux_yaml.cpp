/*
 * SPDX-FileCopyrightText: Copyright (c) <2022> NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include "deepstream_common.h"
#include "deepstream_config_yaml.h"
#include <string>
#include <cstring>
#include <iostream>

using std::cout;
using std::endl;

gboolean
parse_metamux_yaml (NvDsMetaMuxConfig *config, gchar* cfg_file_path)
{
  gboolean ret = FALSE;

  YAML::Node configyml = YAML::LoadFile(cfg_file_path);
  for(YAML::const_iterator itr = configyml["meta-mux"].begin();
     itr != configyml["meta-mux"].end(); ++itr)
  {
    std::string paramKey = itr->first.as<std::string>();
    if (paramKey == "enable") {
      config->enable = itr->second.as<gboolean>();
    } else if (paramKey == "config-file") {
      std::string temp = itr->second.as<std::string>();
      char* str = (char*) malloc(sizeof(char) * 1024);
      std::strncpy (str, temp.c_str(), 1024);
      config->config_file_path = (char*) malloc(sizeof(char) * 1024);
      if (!get_absolute_file_path_yaml (cfg_file_path, str,
            config->config_file_path)) {
        g_printerr ("Error: Could not parse config-file-path in metamux.\n");
        g_free (str);
        goto done;
      }
      g_free (str);
    } else {
      cout << "[WARNING] Unknown param found in metamux: " << paramKey << endl;
    }
  }

  ret = TRUE;
done:
  if (!ret) {
    cout <<  __func__ << " failed" << endl;
  }
  return ret;
}
