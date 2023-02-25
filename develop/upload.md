# Go 流式文件上传

普通文件上传:

```
func commonUploadFile(url, filePath string, fields map[string]string) error {
    file, err := os.Open(filePath)
    if err != nil {
        return err
    }
    stat, _ := file.Stat()
    defer file.Close()
    
    // buffer for store multipart data
    byteBuf := &bytes.Buffer{}
    writer := multipart.NewWriter(byteBuf)
    
    // part: parameters
    for k, v := range fields {
        err = writer.WriteField(k, v)
        if err != nil {
            return err
        }
    }
    
    // part: file
    formWriter, err := writer.CreateFormFile("file", stat.Name())
    if err != nil {
        return err
    }
    _, err = io.Copy(formWriter, file)
    if err != nil {
        return err
    }
    
    contentType := writer.FormDataContentType()
    
    // part: latest boundary
    // when multipart closed, latest boundary is added
    writer.Close()
    
    // construct request
    req, _ := http.NewRequest("POST", url, byteBuf)
    req.Header.Set("Content-Type", contentType)
    req.Header.Set("Content-Length", fmt.Sprintf("%v", byteBuf.Len()))
    
    // process request
    client := &http.Client{Timeout: 10 * time.Minute}
    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    log.Println(resp.StatusCode)
    log.Println(resp.Header)
    return nil
}
```

上面代码在上传图片等一些小文件是没有问题的. 但是当上传比较大的文件时, 上面的代码可能就会出现问题了, 内存会随着大文件
上传激增. 根因在于**每次上传文件时, 都会先将文件读入到内存当中(代码中 io.Copy() 函数调用), 然后进行发送**. 那该如
何解决这个问题了? 流式文件上传. 每次读取一小块数据到内存, 发送, 然后重复前面的操作直到文件发送完成. 流式文件上传可以
进行内存复用, 分配的总内存会大大减少.

流式文件上传的实现也是有多种方式, 下面列举两种实现方式, 单文件的 io.Pipe, 多文件的 io.MultiReader.

### 单文件 io.Pipe 方式

```
func uploadFile(url, filePath string, fields map[string]string) error {
	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	stat, _ := file.Stat()
	defer file.Close()

	// buffer for store multipart data
	byteBuf := &bytes.Buffer{}
	writer := multipart.NewWriter(byteBuf)

	// part: parameters
	for k, v := range fields {
		err = writer.WriteField(k, v)
		if err != nil {
			return err
		}
	}

	// part: file
	_, err = writer.CreateFormFile("file", stat.Name())
	if err != nil {
		return err
	}

	contentType := writer.FormDataContentType()

	nheader := byteBuf.Len()
	header := make([]byte, nheader)
	_, _ = byteBuf.Read(header)

	// part: latest boundary
	// when multipart closed, latest boundary is added
	writer.Close()
	nboundary := byteBuf.Len()
	boundary := make([]byte, nboundary)
	_, _ = byteBuf.Read(boundary)

	// calculate content length
	totalSize := int64(nheader) + stat.Size() + int64(nboundary)

	//use pipe to pass request
	rd, wr := io.Pipe()
	defer rd.Close()

	go func() {
		defer wr.Close()
		// write multipart
		_, _ = wr.Write(header)

		// write file
		buf := make([]byte, 16*1024)
		for {
			n, err := file.Read(buf)
			if err != nil {
				break
			}
			_, _ = wr.Write(buf[:n])
		}

		// write boundary
		_, _ = wr.Write(boundary)
	}()

	// construct request with rd
	req, _ := http.NewRequest("POST", url, rd)
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("Content-Length", fmt.Sprintf("%v", totalSize))

	// process request
	client := &http.Client{Timeout: 10 * time.Minute}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	log.Println(resp.StatusCode)
	log.Println(resp.Header)
	return nil
}
```

复用了 "mime/multipart" 库提供的文件上传函数, 使用 io.Pipe 创建了一个管道, 同时进行一端读, 一端写的功能, 每次读
取都使用了缓存.

### 多文件 io.MultiReader 方式

```
func randomBoundary() string {
	var buf [30]byte
	_, err := io.ReadFull(rand.Reader, buf[:])
	if err != nil {
		panic(err)
	}
	return fmt.Sprintf("%x", buf[:])
}

var quoteEscaper = strings.NewReplacer("\\", "\\\\", `"`, "\\\"")

func escapeQuotes(s string) string {
	return quoteEscaper.Replace(s)
}

// Multipart request has the following structure:
//  POST /upload HTTP/1.1
//  Other-Headers: ...
//  Content-Type: multipart/form-data; boundary=$boundary
//  \r\n
//  --$boundary\r\n      <-request body starts here
//  Content-Disposition: form-data; name="field1"; filename="xyz.img"\r\n
//  Content-Type: application/octet-stream\r\n
//  Content-Length: 4\r\n
//  \r\n
//  $content\r\n
//  --$boundary\r\n
//  Content-Disposition: form-data; name="field2"; filename="pwd.img"\r\n
//  ...
//  --$boundary--\r\n
func uploadFile(url string, fields map[string]interface{}) error {
	boundary := randomBoundary()
	totalSize := 0
	contentType := fmt.Sprintf("multipart/form-data; boundary=%s", boundary)

	parts := make([]io.Reader, 0)
	CRLF := "\r\n"

	fieldBoundary := "--" + boundary + CRLF

	for k, v := range fields {
		parts = append(parts, strings.NewReader(fieldBoundary))
		totalSize += len(fieldBoundary)
		if v == nil {
			continue
		}
		switch val := v.(type) {
		case string:
			header := fmt.Sprintf(`Content-Disposition: form-data; name="%s"`, escapeQuotes(k))
			parts = append(
				parts,
				strings.NewReader(header+CRLF+CRLF),
				strings.NewReader(val),
				strings.NewReader(CRLF),
			)
			totalSize += len(header) + 2*len(CRLF) + len(val) + len(CRLF)
			continue
		case fs.File:
			stat, _ := val.Stat()
			contentType := mime.TypeByExtension(filepath.Ext(stat.Name()))
			header := strings.Join([]string{
				fmt.Sprintf(`Content-Disposition: form-data; name="%s"; filename="%s"`, escapeQuotes(k), escapeQuotes(stat.Name())),
				fmt.Sprintf(`Content-Type: %s`, contentType),
				fmt.Sprintf(`Content-Length: %d`, stat.Size()),
			}, CRLF)
			parts = append(
				parts,
				strings.NewReader(header+CRLF+CRLF),
				val,
				strings.NewReader(CRLF),
			)
			totalSize += len(header) + 2*len(CRLF) + int(stat.Size()) + len(CRLF)
			continue
		}
	}

	finishBoundary := "--" + boundary + "--" + CRLF
	parts = append(parts, strings.NewReader(finishBoundary))
	totalSize += len(finishBoundary)

	// construct request with reader
	req, _ := http.NewRequest("POST", url, io.MultiReader(parts...))
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("Content-Length", fmt.Sprintf("%d", totalSize))

	// process request
	client := &http.Client{Timeout: 10 * time.Minute}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}

	log.Println(resp.StatusCode)
	log.Println(resp.Header)
	defer resp.Body.Close()
	return nil
}
```

重写了文件上传的代码, 手动填充各个字段. 使用了 io.MultiReader 可以将多个 reader 合并成一个, 延迟逐步将 reader 当
中的内存读取到内存, 然后发送, 也达到了内存的复用效果.

使用这种方式, 需要对文件上传的协议有深入的理解, 但是此种方式更加灵活.

