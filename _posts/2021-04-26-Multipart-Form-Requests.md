---

layout: post
title:  "How To Upload Data To A Server: Multipart/Form-Data HTTP Requests in Swift"
date:   2021-04-26 21:03:36 +0530
categories: Swift HTTP iOS URLSession
doctest: false

---

So you are making your first face beautifier**©** app and it’s about time to upload some images to a server. The backend person asks you to do it via a type of HTTP POST request known as `multipart/form-data`. Soon you come to realise that `URLSession` does not provide you with an out of the box `URLRequest` or `DataTask` for this specific task, despite the fact that this is a very standard way of uploading data.

And that’s when you reach for [Alamofire](https://github.com/Alamofire/Alamofire).

**Or** you can stick with `URLSession` and make your own `MultipartFormDataRequest`

It works like this:
```swift
func uploadImage(imageData: Data) {
    let request = MultipartFormDataRequest(url: URL(string: "https://server.com/uploadPicture")!)
    request.addDataField(named: "profilePicture", data: imageData, mimeType: "img/jpeg")
    URLSession.shared.dataTask(with: request, completionHandler: {
        ...
    }).resume()
}
```

`MultipartFormDataRequest` is very similar to a `URLRequest` in that it is initialised by a URL. The URL endpoint that you will be sending data to.

Use `addTextField` to send text and `addDataField` to send anything that can be converted to `Data` (images, audio, Grand Theft Auto 2 savefiles, you name it)

```swift
struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    func addDataField(named name: String, data: Data, mimeType: String) {
        httpBody.append(dataFormField(named: name, data: data, mimeType: mimeType))
    }

    private func dataFormField(named name: String,
                               data: Data,
                               mimeType: String) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }
}

extension NSMutableData {
  func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}
```

You also need a function to convert a `MultipartFormDataRequest` to a `URLRequest` in order to be able to create `URLSessionDataTasks`

```swift
func asURLRequest() -> URLRequest {
    var request = URLRequest(url: url)

    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    httpBody.appendString("--\(boundary)--")
    request.httpBody = httpBody as Data
    return request
}
```

Bonus round:

A handy `URLSession` extension. You can also make this an upload task, or use background sessions etc.

```swift
extension URLSession {
    func dataTask(with request: MultipartFormDataRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
    -> URLSessionDataTask {
        return dataTask(with: request.asURLRequest(), completionHandler: completionHandler)
    }
}
```

And this is it. You can now upload your image to the server. A very good example of how simple (or scary) HTTP can be.

I didn’t go into much detail about the HTTP specifics because:

1.  This is a sort of tl;dr blog post where I’m sharing some (I hope) useful code with you
2.  Donny Wals has done an excellent job at explaining this in [his blog post](https://www.donnywals.com/uploading-images-and-forms-to-a-server-using-urlsession/)
3.  You can read about it [here](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST)

Feel free to [contact me](mailto:orjpap@gmail.com) for tips, feedback, opinions.

Thank you for reading!