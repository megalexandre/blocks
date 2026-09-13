# Base da Cirrus Labs: já traz Flutter, Android SDK (platform 36, build-tools
# 36.0.0) e JDK montados, com as licenças aceitas.
FROM ghcr.io/cirruslabs/flutter:stable

# A tag `stable` flutua e hoje traz a 3.44.0. Fixamos a mesma versão do host
# para o pubspec.lock não oscilar entre quem builda dentro e fora do container.
ARG FLUTTER_VERSION=3.47.2

# A base já traz um usuário comum em uid/gid 1000; reaproveitamos em vez de
# criar outro. O VS Code remapeia o uid para o seu no host automaticamente.
ARG USERNAME=ubuntu

# Toolchain do alvo Linux desktop, mais o que o loop de verificação usa: Xvfb
# para rodar sem tela, XTest para injetar mouse, e Python com numpy/PIL para
# ler os frames capturados.
RUN apt-get update && apt-get install -y --no-install-recommends \
      clang cmake ninja-build pkg-config \
      libgtk-3-dev liblzma-dev libstdc++-12-dev \
      xvfb x11-utils libx11-6 libxtst6 imagemagick \
      python3 python3-numpy python3-pil \
      git curl unzip xz-utils ca-certificates sudo \
    && rm -rf /var/lib/apt/lists/*

# A imagem base roda como root. Trabalhar como usuário comum evita que todo
# arquivo criado aqui apareça como root no seu diretório do host.
RUN echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# A base não traz o NDK, e o Gradle tentaria baixá-lo no primeiro `build apk` —
# em um diretório que é do root, então falharia depois de vários minutos.
# Precisa bater com o `flutter.ndkVersion` da versão fixada acima.
ARG ANDROID_NDK_VERSION=28.2.13676358
RUN yes | sdkmanager --install "ndk;$ANDROID_NDK_VERSION" > /dev/null \
    && chmod -R a+rwX "$ANDROID_HOME"

# Fixa a versão do Flutter. O clone da base é raso, então a tag é buscada
# explicitamente.
RUN git config --global --add safe.directory "$FLUTTER_ROOT" \
    && git -C "$FLUTTER_ROOT" fetch --depth 1 origin \
         "refs/tags/$FLUTTER_VERSION:refs/tags/$FLUTTER_VERSION" \
    && git -C "$FLUTTER_ROOT" checkout "$FLUTTER_VERSION" \
    && chown -R $USERNAME:$USERNAME "$FLUTTER_ROOT"

ENV FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/home/$USERNAME/.pub-cache

USER $USERNAME

# Baixa os artefatos do alvo Linux agora, para o primeiro build não esperar.
RUN git config --global --add safe.directory "$FLUTTER_ROOT" \
    && flutter --version \
    && flutter precache --linux

# O Flutter escreve em bin/cache a cada invocação. Como o VS Code remapeia o
# uid do usuário para o do host, não dá para fixar um dono aqui: qualquer uid
# precisa conseguir escrever, ou todo comando falha com "Permission denied".
#
# Pelo mesmo motivo o safe.directory vai em --system, e não --global: o SDK é
# um repositório git de dono diferente de quem o executa, e sem isso o git
# recusa com "dubious ownership" e nenhum comando do Flutter roda.
USER root
RUN chmod -R a+rwX "$FLUTTER_ROOT" \
    && git config --system --add safe.directory "$FLUTTER_ROOT"
USER $USERNAME
