#!/bin/sh
mvn -B archetype:generate -DgroupId="$1" -DartifactId="$2" -Dpackage="$3" -DarchetypeCatalog=http://jabaraster.github.io/maven/archetype-catalog.xml -DarchetypeGroupId=jabaraster -DarchetypeArtifactId=archetype-wicket-jpa
