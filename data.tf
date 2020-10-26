# Get the most recent Amazon Linux 2 AMI
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

# Script for copying certificate, web server config and service files from localhost to the Seafile server
data "template_file" "file_copy" {
  template = <<EOF
        #!/bin/bash
        echo ${base64encode(file(var.server_cert_path))} | base64 --decode > /etc/ssl/certs/server.crt
        echo ${base64encode(file(var.server_key_path))} | base64 --decode > /etc/ssl/certs/server.key
        echo ${base64encode(file("conf/seafile.conf"))} | base64 --decode > /etc/nginx/conf.d/seafile.conf
        echo ${base64encode(file("conf/seafile.service"))} | base64 --decode > /usr/lib/systemd/system/seafile.service
        echo ${base64encode(file("conf/seahub.service"))} | base64 --decode > /usr/lib/systemd/system/seahub.service
        EOF
}

# User data including all commands for Seafile setup
data "template_file" "user_data" {
  template = <<EOF
        #! /bin/bash

	# Install dependencies
	yum -y update
	amazon-linux-extras install epel
	yum -y install gcc gcc-c++ python3 python3-devel python-imaging MySQL-python python-simplejson s3fs-fuse nginx mariadb mariadb-server
	pip3 install Pillow pylibmc captcha jinja2 sqlalchemy psd-tools django-pylibmc django-simple-captcha python3-ldap

	# MariaDB setup:
	# - perform steps from mysql_secure_installation: Set root password, delete anonymous users, disable remote login for root, remove test database
	# - create Seafile databases and user
 	systemctl start mariadb
 	systemctl enable mariadb
 	mysql --user=root -e "\
		UPDATE mysql.user SET Password=PASSWORD('${var.mysql_root_password}') WHERE User='root'; \
		DELETE FROM mysql.user WHERE User=''; \
		DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); \
		DROP DATABASE IF EXISTS test; \
 		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; \
		CREATE DATABASE ccnet_db CHARACTER SET = 'utf8'; \
		CREATE DATABASE seafile_db CHARACTER SET = 'utf8'; \
		CREATE DATABASE seahub_db CHARACTER SET = 'utf8'; \
		CREATE USER 'seafile'@'localhost' IDENTIFIED BY '${var.mysql_seafile_password}'; \
		GRANT ALL PRIVILEGES ON \`ccnet_db\`.* TO seafile@localhost; \
		GRANT ALL PRIVILEGES ON \`seafile_db\`.* TO seafile@localhost; \
		GRANT ALL PRIVILEGES ON \`seahub_db\`.* TO seafile@localhost; \
		FLUSH PRIVILEGES;"

        # Create s3fs mount point
	mkdir /data

	# Install Seafile
	mkdir /usr/share/nginx/html/seafile && cd $_
	wget ${var.download_url}
	tar -xzf seafile-server*.tar.gz && rm $_
	cd seafile-server*
	/usr/share/nginx/html/seafile/seafile-server*/setup-seafile-mysql.sh auto -i 127.0.0.1 -p 8082 -d /data/${var.bucket_name} -e 1 -u seafile -w ${var.mysql_seafile_password} -c ccnet_db -s seafile_db -b seahub_db
	sed -i 's#SERVICE_URL.*#SERVICE_URL = https://${var.dns_record}/seafile#' /usr/share/nginx/html/seafile/conf/ccnet.conf
	printf "FILE_SERVER_ROOT = 'https://${var.dns_record}/seafhttp'\nSERVE_STATIC = False\nMEDIA_URL = '/seafmedia/'\nSITE_ROOT = '/seafile/'\nLOGIN_URL = '/seafile/accounts/login/'\nCOMPRESS_URL = MEDIA_URL\nSTATIC_URL = MEDIA_URL + 'assets/'" >> /usr/share/nginx/html/seafile/conf/seahub_settings.py

	# Set seafile-data directoy to s3fs mount point
	ln -s /data/${var.bucket_name} /usr/share/nginx/html/seafile/seafile-data

	# Copy local files to server
	${data.template_file.file_copy.rendered}

	# Set host name in nginx config
	sed -i "s/#HOSTNAME#/${var.dns_record}/g" /etc/nginx/conf.d/seafile.conf

	# Load new service files, start Seafile
	systemctl daemon-reload
	systemctl start seafile
	systemctl enable seafile

	# Set up Seahub admin on first start (set "password" flag to "false" in check_init_admin script before, so that credentials can be piped in)
	sed -i "s/password=True/password=False/g" /usr/share/nginx/html/seafile/seafile-server-latest/check_init_admin.py
	printf "${var.seahub_email}\n${var.seahub_password}\n${var.seahub_password}\n" | /usr/share/nginx/html/seafile/seafile-server-latest/seahub.sh start

	# Start Seahub and nginx using the service files
	/usr/share/nginx/html/seafile/seafile-server-latest/seahub.sh stop
	systemctl start seahub
	systemctl enable seahub
	systemctl start nginx
	systemctl enable nginx

	# Mount S3 bucket and create basic fs structure
	s3fs -o iam_role=${aws_iam_role.instance_role.id} -o url=${local.s3fs_endpoint_url} -o nonempty -o enable_noobj_cache -o ensure_diskfree=1024 -o use_cache=/tmp/s3fs -o noatime ${var.bucket_name} /data/${var.bucket_name}
	mkdir -p /data/${var.bucket_name}/tmpfiles /data/${var.bucket_name}/httptemp/cluster-shared /data/${var.bucket_name}/storage/blocks

	# Exclude s3fs from updatedb indexing
	sed -i 's/PRUNEPATHS = "/\PRUNEPATHS = "\/data /g; s/PRUNEFS = "/PRUNEFS = "fuse.s3fs /g' /etc/updatedb.conf

	# Mount bucket on start-up
	echo 's3fs#${var.bucket_name} /data/${var.bucket_name} fuse _netdev,iam_role=${aws_iam_role.instance_role.id},url=${local.s3fs_endpoint_url},nonempty,enable_noobj_cache,ensure_diskfree=1024,use_cache=/tmp/s3fs,noatime 0 0' >> /etc/fstab
	EOF
}
