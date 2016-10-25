# Chime.IO-Client-Swift
A chat app connecting to a Chime.IO server.

## Get apiKey & clientKey
Make sure you have a running [chimeio-server](https://github.com/JmeHsieh/chimeio-server).<br />
Get your `apiKey`, and `clientKey`:

#### Create a Developer Account
Make a `POST` request to `your_server:port/developers` with required parameters:

```
email: develoepr_email
username: developer_username
password: developer_password
```
Then you will get your developer `token`

#### Create an Application
Make a `POST` request to `your_server:port/applications` with required parameters:

```
title: application_name
token: developer_token
```
Then you will get your `apiKey` and `clientKey`

## Run

Getting up and running.

1. Make sure you have [Carthage](https://github.com/Carthage/Carthage) installed and setup on your machine.
2. Build depedencies:
	
	```
	$ carthage update --platform iOS
	```
3. Replace the following constant in `ChIO.swift`:

	```
	let xipURL = NSURL(string: "your_server.xip.io:port")!
    let localURL = NSURL(string: "your_server:port")!
    let instance = ChIO(apiKey: "your_apiKey", clientKey: "your_clientKey", url: localURL)
	```
4. Now build and run your Xcode project.

## License
[MIT license](LICENSE).