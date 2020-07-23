set -euo pipefail

main()
{
    get_posts 0
}

get_posts() {

local JAR_PATH="sample-2.0.jar"
    
local access_token=$(curl --location --request POST 'https://anypoint.mulesoft.com/accounts/login' \
--header 'Content-Type: application/json' \
--data-raw '{
	"username": "sutheer",
	"password": "Dorittos+2"
}'| jq -r '.access_token' )


echo $access_token    


local organization_id=$(curl --location --request GET 'https://anypoint.mulesoft.com/accounts/api/me' \
--header "Authorization: Bearer $access_token" | jq -r '.user.organization.id' )


echo $organization_id    


local environment_id=$(curl --location --request GET "https://anypoint.mulesoft.com/accounts/api/organizations/$organization_id/environments" \
--header "Authorization: Bearer $access_token" | jq -r '.data[] | select(.type=="sandbox")| .id' )

echo $environment_id


local application_json=$(curl --location --request GET 'https://anypoint.mulesoft.com/hybrid/api/v1/applications' \
--header "X-ANYPNT-ENV-ID: $environment_id" \
--header "X-ANYPNT-ORG-ID: $organization_id" \
--header "Authorization: Bearer $access_token" | jq -r '.data[] | select(.name == "SampleApp") | {applicationid:.id,targetId:.target.id,artifactname:.artifact.name}' )

echo $application_json


local application_id=$(echo $application_json | jq -r '.applicationid')
local artifactName=$(echo $application_json | jq -r '.artifactname')
local targetId=$(echo $application_json | jq -r '.targetId')

local patch_status_json=$(curl --location --request PATCH "https://anypoint.mulesoft.com/hybrid/api/v1/applications/$application_id" \
--header "x-anypnt-env-id: $environment_id" \
--header "x-anypnt-org-id: $organization_id" \
--header 'Content-Type: multipart/form-data' \
--header "Authorization: Bearer $access_token" \
--form "artifactName=$artifactName" \
--form "targetId=$targetId" \
--form "file=@ $JAR_PATH" | jq -r '.data | {desiredStatus:.desiredStatus,lastReportedStatus:.lastReportedStatus,started:.started}' )

echo $patch_status_json


}

main
