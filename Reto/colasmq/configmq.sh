#!/bin/bash

    set -x 

	PATHJSONMODULE="coloasmq/mq.json"
	ambiente="dev"
	ambmurex="dev1"
	modulmurex="VALORACION"
	CHARRTCONCAT=","
	
	TIPOCOLASMQ=$(jq -r '.colas[].tipo' mq.json|sort| uniq  $PATHJSONMODULE )
	
	#echo $modulesenv

	for tipomq in ${TIPOCOLASMQ[@]} ; do
				
		echo "######### $tipomq #############"
		
		colasenv=$(jq -r '.colas | .[]|select(.tipo=="$tipomq")|.nombre' $PATHJSONMODULE)
		
		for elem in ${colasenv[@]} ; do
			var=$elem$CHARRTCONCAT$var
		done
		result=$(echo $var|sed -e 's/.$//')
		var=""
		echo $result
		
	done
	