#!/bin/bash

# This script copies Athena database and associated tables from one region to other 
# Requires the AWS CLI configured with source region and jq

#Function to create associated tables
createAssociatedTables () {
	for AssociatedTable in ${AssociatedTables[*]}; do
		echo "Creating json for ${AssociatedTable} on DB ${AthenaDatabase}"
		aws glue get-table --database-name ${AthenaDatabase} --name ${AssociatedTable} | jq 'del(.Table.CreatedBy)' | jq 'del(.Table.IsRegisteredWithLakeFormation)' | jq 'del(.Table.CatalogId)' | jq 'del(.Table.UpdateTime)' | jq 'del(.Table.CreateTime)' | jq 'del(.Table.Owner)' | jq 'del(.Table.DatabaseName)' | jq 'del(.Table.VersionId)' | jq 'del(.Table.Retention)' | jq 'del(.Table.LastAccessTime)' | jq .Table > AssociatedTables.json
		aws glue create-table --database-name ${AthenaDatabase} --table-input file://table.json --region us-east-1
	done
}

# Main script to get db in one region and create in other region.
Associated_databases=($yourAthenaDbNmae) # you can give a single db name by replacing $yourAthenaDbNmae with your db name.
#AssociatedDatabases=$(aws athena list-databases --catalog-name AwsDataCatalog | jq -r .DatabaseList[].Name) 
for AthenaDatabase in ${AssociatedDatabases[*]}; do
	echo "Creating DB ${AthenaDatabase} in NV region"
	aws glue get-database --name ${AthenaDatabase} | jq 'del(.Database.CreateTime)' | jq 'del(.Database.CatalogId)' | jq .Database > db.json
	aws glue create-database --database-input file://db.json --region us-east-1 # Need exception handing here if db is already created
	AssociatedTables=$(aws glue get-tables --database-name ${AthenaDatabase} | jq -r .TableList[].Name)
	createAssociatedTables 
done
