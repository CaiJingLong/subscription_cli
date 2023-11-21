# A cli for subscribing some release resources

Developing...

## About config file

The config file is yaml file, and
the file name is `scli.yaml`.
This is an [example file](scli.example.yaml).

### Environment Variables

The config file support Environment Variables.

You need use `${ENV_NAME}` to use Environment Variables.

like this:

```yaml
config:
  githubToken: ${GITHUB_TOKEN}

```

The Environment Variables will be replaced by the real value when the program is running.

### config

The config section is the global config.

Every config item in this section will be used in every job.

#### githubToken

The github token for github api.

#### proxy

The proxy for http request.

If you use clash, you can use

```yaml
config:
  proxy:
    host: localhost
    port: 7890
```

### jobs

The jobs section is the job list.

Every job will be run in order.

#### job params

Some job have variable params.

The params will be used in the job definition.

You can use `#{paramName}` to use the params.

But the variable params not support all place.

You can see option table to know the variable params support or not.

Some job have inner variable params.

#### base option

The job have some base option.

| option | type | description | required | default value |
| --- | --- | --- | --- | --- |
| name | string | the job name | true | |
| description | string | the job description | false | null |
| type | string | the job type | true | |
| enabled | boolean | the job is enabled | false | true |
| overwrite | boolean | the job will overwrite the old data | false | false |
| workingDir | string | the job working dir | false | the current dir |
| params | object | the job params | false | null |

```yaml
jobs:
  - name: job name
    type: See the type in the next section
```

#### Github release

type: `github-release` or `gr`

The job will get the github release assets.

| option | type | description | required | default value | support variable params |
| --- | --- | --- | --- | --- | --- |
| owner | string | the github repo owner | true | | false |
| repo | string | the github repo name | true | | false |
| asset | string | the asset name | true | | true |

inner variable params:

| param name | description |
| --- | --- |
| version | the name of release |
