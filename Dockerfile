###########################################################
# Dockerfile that builds a TF2 Classic Gameserver
###########################################################
FROM cm2network/steamcmd:root AS build_stage

LABEL maintainer="joshuafhiggins@gmail.com"

ENV STEAMAPPID 244310
ENV STEAMAPP tf2classic
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"

RUN set -x \
	# Add i386 architecture
	&& dpkg --add-architecture i386 \
	# Install, update & upgrade packages
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		wget=1.21-1+deb11u1 \
		ca-certificates=20210119 \
		lib32z1=1:1.2.11.dfsg-2+deb11u2 \
		libncurses5:i386=6.2+20201114-2+deb11u1 \
		libbz2-1.0:i386=1.0.8-4 \
		libtinfo5:i386=6.2+20201114-2+deb11u1 \
		libcurl3-gnutls:i386=7.74.0-1.3+deb11u7 \
		p7zip-full \
	&& mkdir -p "${STEAMAPPDIR}" \
	# Create autoupdate config
	&& { \
		echo '@ShutdownOnFailedCommand 1'; \
		echo '@NoPromptForPassword 1'; \
		echo 'force_install_dir '"${STEAMAPPDIR}"''; \
		echo 'login anonymous'; \
		echo 'app_update '"${STEAMAPPID}"''; \
		echo 'quit'; \
	   } > "${HOMEDIR}/${STEAMAPP}_update.txt" \
	# && chmod +x "${HOMEDIR}/entry.sh" \
	&& chown -R "${USER}:${USER}" "${STEAMAPPDIR}" "${HOMEDIR}/${STEAMAPP}_update.txt" \
	# Clean up
	&& rm -rf /var/lib/apt/lists/*

COPY entry.sh ${HOMEDIR}
RUN chmod +x "${HOMEDIR}/entry.sh" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh"

FROM build_stage AS bullseye-base

ENV SRCDS_FPSMAX=300 \
	SRCDS_TICKRATE=66 \
	SRCDS_PORT=27015 \
	SRCDS_TV_PORT=27020 \
        SRCDS_NET_PUBLIC_ADDRESS="0" \
        SRCDS_IP="0" \
	SRCDS_MAXPLAYERS=16 \
	SRCDS_TOKEN=0 \
	SRCDS_RCONPW="changeme" \
	SRCDS_PW="changeme" \
	SRCDS_STARTMAP="ctf_2fort" \
	SRCDS_REGION=3 \
        SRCDS_HOSTNAME="New \"${STEAMAPP}\" Server" \
        SRCDS_WORKSHOP_START_MAP=0 \
        SRCDS_HOST_WORKSHOP_COLLECTION=0 \
        SRCDS_WORKSHOP_AUTHKEY=""

# Switch to user
USER ${USER}

WORKDIR ${HOMEDIR}

CMD ["bash", "entry.sh"]

# Expose ports
EXPOSE 27015/tcp \
	27015/udp \
	27020/udp
