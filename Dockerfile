FROM microsoft/dotnet:2.1.403-sdk-alpine3.7 AS build
ARG TRAVIS_BUILD_NUMBER
ARG TRAVIS_PULL_REQUEST_SHA
ARG TRAVIS_COMMIT
ARG TRAVIS_PULL_REQUEST
ARG TRAVIS_BRANCH
ARG MYGET_API_KEY

RUN apk add nodejs --no-cache git

WORKDIR /src

COPY ./src/*.sln ./
COPY ./src/*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p ./${file%.*}/ && mv $file ./${file%.*}/; done

COPY ./NuGet.Config ./

RUN dotnet restore --runtime=alpine.3.7-x64

COPY ./src .

WORKDIR /build

COPY ./build/build.csproj .

RUN dotnet restore

COPY ./build .

WORKDIR /docs

COPY ./docs/* ./

RUN dotnet restore

WORKDIR /

RUN TRAVIS_BUILD_NUMBER=$TRAVIS_BUILD_NUMBER \
  MYGET_API_KEY=$MYGET_API_KEY \
  TRAVIS_PULL_REQUEST_SHA=$TRAVIS_PULL_REQUEST_SHA \
  TRAVIS_COMMIT=$TRAVIS_COMMIT \
  TRAVIS_PULL_REQUEST=$TRAVIS_PULL_REQUEST \
  TRAVIS_BRANCH=$TRAVIS_BRANCH \
  dotnet run --project build/build.csproj

FROM build as publish

WORKDIR /src/SqlStreamStore.HAL.DevServer

RUN dotnet add package ILLink.Tasks --version=0.1.5-preview-1841731 --source=https://dotnet.myget.org/F/dotnet-core/api/v3/index.json
RUN dotnet publish --configuration=Release --output=/publish --runtime=alpine.3.7-x64 /p:ShowLinkerSizeComparison=true

FROM microsoft/dotnet:2.1.5-runtime-deps-alpine3.7 AS runtime

WORKDIR /app
COPY --from=publish /publish ./

ENTRYPOINT ["/app/SqlStreamStore.HAL.DevServer"]
