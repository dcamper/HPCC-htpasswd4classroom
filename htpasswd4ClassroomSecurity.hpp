/*##############################################################################

    HPCC SYSTEMS software Copyright (C) 2013 HPCC Systems®.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
############################################################################## */

#ifndef HTPASSWD4CLASSROOMSECURITY_HPP_
#define HTPASSWD4CLASSROOMSECURITY_HPP_

#ifndef HTPASSWD4CLASSROOMSECURITY_API

#ifndef HTPASSWD4CLASSROOMSECURITY_EXPORTS
    #define HTPASSWD4CLASSROOMSECURITY_API DECL_IMPORT
#else
    #define HTPASSWD4CLASSROOMSECURITY_API DECL_EXPORT
#endif //HTPASSWD4CLASSROOMSECURITY_EXPORTS

#endif 

extern "C" 
{
    HTPASSWD4CLASSROOMSECURITY_API ISecManager * createInstance(const char *serviceName, IPropertyTree &secMgrCfg, IPropertyTree &bndCfg);
}

#endif // HTPASSWD4CLASSROOMSECURITY_HPP_
