#!/usr/bin/env bash

log() {
    green="\033[32;1m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

    read -d '' -r OPENSSL_COMMON <<-'EOF'
[ req ]
    distinguished_name = req_distinguished_name
    attributes = req_attributes
[ req_distinguished_name ]
    countryName = Country Name (2 letter code)
    countryName_min = 2
    countryName_max = 2
    countryName_default = US
    0.organizationName = Organization Name (eg, company)
    0.organizationName_default = StrongSwan VPN
    commonName = Common Name (eg, fully qualified host name)
    commonName_max = 64
[ req_attributes ]
    challengePassword = A challenge password
    challengePassword_min = 4
    challengePassword_max = 20
EOF

function genca() {
	cat > openssl.cnf <<-EOF
$OPENSSL_COMMON
[ ca ]
    subjectKeyIdentifier = hash
    basicConstraints = critical, CA:true
    keyUsage = critical, cRLSign, keyCertSign
EOF

    log "gen ca private key ...."
    openssl genrsa -out ca.key 4096
	
    log "sign self ca cert ...."
    openssl req -x509 -new -nodes \
        -config openssl.cnf \
        -extensions ca \
        -key ca.key \
        -subj "/C=US/O=StrongSwan VPN/CN=VPN CA" \
        -days 3650 \
        -out ca.crt
}

function genserver() {
    if [[ !(-f ca.crt) || !(-f ca.key) ]]; then
        genca
    fi
		
    STRONGSWAN_CLIENT_NAME="server"
	CN="vpn-server.com"
	SAN="DNS: vpn-server.com" # IP:192.168.1.100, DNS: vpn-server.com, DNS: *.google.com
	cat > openssl.cnf <<-EOF
$OPENSSL_COMMON
[ ca ]
    subjectKeyIdentifier = hash
    basicConstraints = critical, CA:true
    keyUsage = critical, cRLSign, keyCertSign
[ server ]
    authorityKeyIdentifier = keyid
    subjectAltName = $SAN
    extendedKeyUsage = serverAuth, 1.3.6.1.5.5.8.2.2
EOF
	
    log "gen server $STRONGSWAN_CLIENT_NAME private key ...."
    openssl genrsa -out ${STRONGSWAN_CLIENT_NAME}.key 4096
	
    log "gen server $STRONGSWAN_CLIENT_NAME cert request ...."
    openssl req -new \
		-config openssl.cnf \
        -extensions server \
        -key ${STRONGSWAN_CLIENT_NAME}.key \
        -subj "/C=US/O=StrongSwan VPN/CN=$CN" \
		-out ${STRONGSWAN_CLIENT_NAME}.csr
	
    log "sign server $STRONGSWAN_CLIENT_NAME cert request with CA ...."
    openssl x509 -req \
		-extfile openssl.cnf \
        -extensions server \
        -in ${STRONGSWAN_CLIENT_NAME}.csr \
        -CA ca.crt \
        -CAkey ca.key \
        -CAcreateserial -days 3650 \
        -out ${STRONGSWAN_CLIENT_NAME}.crt
}

function genclient() {
    if [[ !(-f ca.crt) || !(-f ca.key) ]]; then
        genca
    fi
	
    STRONGSWAN_CLIENT_NAME=$1
	STRONGSWAN_DOMAIN="vpn-server.com"
	CN= "${STRONGSWAN_CLIENT_NAME}@${STRONGSWAN_DOMAIN}"
	SAN="email:${STRONGSWAN_CLIENT_NAME}@${STRONGSWAN_DOMAIN}" # email: myvpn@google.com URI:https://www.baidu.com
	cat > openssl.cnf <<-EOF
$OPENSSL_COMMON
[ ca ]
    subjectKeyIdentifier = hash
    basicConstraints = critical, CA:true
    keyUsage = critical, cRLSign, keyCertSign
[ client ]
    authorityKeyIdentifier = keyid
    subjectAltName = $SAN
    extendedKeyUsage = serverAuth, 1.3.6.1.5.5.8.2.2
EOF

    log "gen client $STRONGSWAN_CLIENT_NAME private key ...."
    openssl genrsa -out ${STRONGSWAN_CLIENT_NAME}.key 4096

    log "gen client $STRONGSWAN_CLIENT_NAME cert request ...."
    openssl req -new -config openssl.cnf \
        -extensions client \
        -key ${STRONGSWAN_CLIENT_NAME}.key \
        -subj "/C=US/O=StrongSwan VPN/CN=$CN" \
        -out ${STRONGSWAN_CLIENT_NAME}.csr

    log "sign client $STRONGSWAN_CLIENT_NAME cert request with CA ...."
    openssl x509 -req -extfile openssl.cnf \
        -extensions client \
        -in ${STRONGSWAN_CLIENT_NAME}.csr \
        -CA ca.crt \
        -CAkey ca.key \
        -CAcreateserial -days 3650 \
        -out ${STRONGSWAN_CLIENT_NAME}.crt

    log "client $STRONGSWAN_CLIENT_NAME p12 ...."
    openssl pkcs12 \
        -in ${STRONGSWAN_CLIENT_NAME}.crt \
        -inkey ${STRONGSWAN_CLIENT_NAME}.key \
        -certfile ca.crt \
        -export \
        -out ${STRONGSWAN_CLIENT_NAME}.p12
}

function usage() {
    read -d '' -r conf <<-'EOF'
Usage:
  cert.sh [options]

options:
  -h, --help       help usage
  -s, --server     gen server cert
  -c, --client     gen client cert
EOF

    echo "$conf"
}

TEMP=`getopt --options hsc: --longoptions help,server,client: \
     -n 'cert.sh' -- "$@"`
if [[ $? != 0 ]]; then
    echo "Terminating..." >&2
    exit 1
fi

eval set -- ${TEMP}


while true ; do
    case "$1" in
        -h|--help)
            usage
            shift ;;
        -s|--server)
            genserver
            shift ;;
        -c|--client)
            genclient $2
            shift 2;;
        --)
            shift
            break ;;
        *)
            usage ;
            exit ;;
    esac
done

