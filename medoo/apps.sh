#!/bin/bash

export APPS_JSON='[
    {
      "url": "https://github.com/frappe/erpnext",
      "branch": "version-15"
    },
    {
      "url": "https://ghp_Vvy@github.com/readerorg/ERPNext-Zatca.git",
      "branch": "main"
    }
  ]'
  
  export APPS_JSON_BASE64=$(echo ${APPS_JSON} | base64 -w 0)