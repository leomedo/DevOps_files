#!/bin/bash

export APPS_JSON='[
    {
      "url": "https://github.com/frappe/erpnext",
      "branch": "version-15"
    },
    {
      "url": "https://github.com/frappe/hrms.git",
      "branch": "version-15"
    },
    {
      "url": "https://ghp_E42@github.com/Mohamed-Shoaib-Python-appy/ERP_signing_fatora.git",
      "branch": "main"
    },
    {
      "url": "https://ghp_Vvy@github.com/readerorg/ERPNext-Zatca.git",
      "branch": "main"
    }
  ]'
  
  export APPS_JSON_BASE64=$(echo ${APPS_JSON} | base64 -w 0)