/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.whirr.service.puppet;

import java.util.regex.Pattern;

/**
 * 
 */
public class PuppetConstants {
  public static final String PUPPET = "puppet";
  public static final String PUPPET_ORIGIN = PUPPET + ".repourl";
  public static final String PUPPET_HIERA_CLASSES = PUPPET + ".hiera_classes";
  public static final String PUPPET_ROLE_PREFIX = PUPPET + ":";
  public static final String MODULE_SOURCE_SUBKEY = "module";

  public static final String MODULES_DIR = "/etc/puppet/modules/";
  public static final String SITE_PP_FILE_LOCATION = "/etc/puppet/manifests/site.pp";
  public static final String CONF_PP_FILE_LOCATION = "/etc/puppet/manifests/extdata/common.csv";
  public static final String HIERA_COMMON_FILE_LOCATION = "/etc/puppet/hieradata/common.yaml";
  public static final String HIERA_CONF_FILE_LOCATION = "/etc/puppet/hiera.yaml";

  public static final Pattern MODULE_KEY_PATTERN = Pattern.compile("^" + PUPPET + "\\.([^.]+)\\."
        + MODULE_SOURCE_SUBKEY + "$");
}
