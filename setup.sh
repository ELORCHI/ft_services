#!/bin/bash -e

banner()
{
	echo -e "\e[35m"
	echo "##############################################################################################"
	echo -en "\e[36m"
	echo "8888888888 88888888888                                          d8b                           "
	echo "888            888                                              Y8P                           "
	echo "888            888                                                                            "
	echo "8888888        888           .d8888b   .d88b.  888d888 888  888 888  .d8888b .d88b.  .d8888b  "
	echo "888            888           88K      d8P  Y8b 888P\"   888  888 888 d88P\"   d8P  Y8b 88K      "
	echo "888            888           \"Y8888b. 88888888 888     Y88  88P 888 888     88888888 \"Y8888b. "
	echo "888            888                X88 Y8b.     888      Y8bd8P  888 Y88b.   Y8b.          X88 "
	echo "888            888   88888888 88888P'  \"Y8888  888       Y88P   888  \"Y8888P \"Y8888   88888P' "
	echo -e "\e[35m"
	echo "##############################################################################################"
	echo -e "\e[31m"
}

image_build()
{
	echo -e "\e[34mBuilding $1 image...\e[33m"
	docker build -t ${1}_alpine srcs/$1/. | grep "Step"
	echo -e "\e[32mSuccessfully built $1 image !\n"
}

deployment_build()
{
	kubectl apply -f srcs/yaml_deployments/$1.yaml &> /dev/null
	echo -e "\e[35mSuccessfully deployed $1 !"
}

service_build()
{
	kubectl apply -f srcs/yaml_services/$1.yaml &> /dev/null
	echo -e "\e[36mSuccessfully exposed $1 !"
}

minikube_setup()
{
	minikube delete
	minikube start --driver=docker --cpus=2
	minikube addons enable metrics-server
	minikube addons enable dashboard &> /dev/null
	echo "🌟  The 'dashboard' addon is enabled"
	minikube addons enable metallb
	kubectl apply -f srcs/yaml_metallb/metallb.yaml
	eval $(minikube docker-env)
	echo
}

images()
{
	imgs=("nginx" "wordpress" "mysql" "phpmyadmin" "ftps" "grafana" "influxdb")

	for img in "${imgs[@]}"
	do
		image_build $img
	done
	echo
}

deployments()
{
	deps=("nginx" "wordpress" "mysql" "phpmyadmin" "ftps" "grafana" "influxdb")

	for dep in ${deps[@]}
	do
		deployment_build $dep
	done
	echo
}

services()
{
	svcs=("nginx" "wordpress" "mysql" "phpmyadmin" "ftps" "grafana" "influxdb")

	for svc in ${svcs[@]}
	do
		service_build $svc
	done
	echo
}

main()
{
	./srcs/vm_setup.sh
	banner
	minikube_setup
	images
	deployments
	services
	echo -e "\e[30mFt_services is ready !"
}

custom()
{
	for i in $@
	do
		if [[ $i =~ ^(nginx|wordpress|mysql|phpmyadmin|ftps|grafana|influxdb)$ ]];
		then
			image_build $i
			deployment_build $i
			service_build $i
		elif [ $i = minikube ]
		then
			minikube_setup
		elif [ $i = img ]
		then
			images
		elif [ $i = dep ]
		then
			deployments
		elif [ $i = svc ]
		then
			services
		fi
	done
}

if [ $1 ]
then
	custom $@
else
	main
fi
