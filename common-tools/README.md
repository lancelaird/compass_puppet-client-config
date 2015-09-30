compass_puppet-common-tools
===========================
## Scope
Common tools and scripts for driving Compass continuous delivery pipeline across build time on jenkins and depoyment automation with puppet master deploymetns via CUDL

* Scripts 
* Scribe

## Assumptions
* All CUDL Components will use "Compass Tools" as their componentgroup

## Scripts integrating with Common Tools
### create-component-version and upload-and-create-component-version
These files files provided in compass_puppet repos supported by these common-tools. The following params should be customized by each app team to upload and create component versions on the command line:

### APP_NAME
Assumed to be name of github puppet repo compass_puppet-james-bond _and_ name of puppet module for this app and hiera key, so no spaces or dashes
```
APP_NAME=dashboard
APP_NAME="discovery-agent"
```
### COMPASS_COMPONENT
The CDA/CUDL Compass Component does NOT have to be same be as package name or github repo name, spaces are ok, but beware components may be registered by AJ (https://thehub.thomsonreuters.com/docs/DOC-887012) in CUDL [with](https://compass.thomsonreuters.com/api/common/cudl/v1/components?component=%22Flex%20Dashboard%22) or [without](http://ermt-app-tst.emea1.ciscloud/api/v1/components?component=Discovery_Agent) '_''s (, e.g.
```
COMPASS_COMPONENT="Flex Dashboard"
COMPASS_COMPONENT="Discovery_Agent"
```

