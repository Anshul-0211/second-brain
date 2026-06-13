import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import http from 'http';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function testFileUpload() {
  try {
    // Create test file with unique name
    const testFileName = path.join(__dirname, `test-upload-${Date.now()}.txt`);
    const testContent = 'This is a test document for file upload testing\nWith some content here';
    fs.writeFileSync(testFileName, testContent);

    console.log('📤 Testing POST /api/items/upload...\n');

    // Read file for upload
    const fileData = fs.readFileSync(testFileName);
    const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substr(2, 16);
    
    // Build multipart body
    let body = '';
    body += `--${boundary}\r\n`;
    body += 'Content-Disposition: form-data; name="content"\r\n\r\n';
    body += 'Remember to write my weekly summary report for all the tasks\r\n';
    body += `--${boundary}\r\n`;
    body += 'Content-Disposition: form-data; name="title"\r\n\r\n';
    body += 'Weekly Summary\r\n';
    body += `--${boundary}\r\n`;
    body += 'Content-Disposition: form-data; name="files"; filename="test-file.txt"\r\n';
    body += 'Content-Type: text/plain\r\n\r\n';
    
    const bodyBuffer = Buffer.concat([
      Buffer.from(body),
      fileData,
      Buffer.from(`\r\n--${boundary}--\r\n`)
    ]);

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/items/upload',
      method: 'POST',
      headers: {
        'x-api-key': 'dev-key',
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': bodyBuffer.length,
      },
    };

    await new Promise((resolve, reject) => {
      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          console.log(`Status: ${res.statusCode}\n`);
          try {
            const parsed = JSON.parse(data);
            console.log('Response:');
            console.log(JSON.stringify(parsed, null, 2));
            
            if (res.statusCode === 201 && parsed.success) {
              console.log('\n✅ File upload test PASSED!');
              console.log(`   - Item ID: ${parsed.item.id}`);
              console.log(`   - Files uploaded: ${parsed.filesUploaded}`);
              console.log(`   - Total size: ${parsed.totalSize} bytes`);
              console.log(`   - File count on item: ${parsed.item.file_count}`);
              console.log(`   - Has attachment: ${parsed.item.has_attachment}`);
            } else {
              console.log('\n❌ File upload test FAILED!');
            }
          } catch (e) {
            console.log('Raw response:', data);
          }
          resolve();
        });
      });

      req.on('error', reject);
      req.write(bodyBuffer);
      req.end();
    });

    // Cleanup
    fs.unlinkSync(testFileName);
  } catch (err) {
    console.error('❌ Test error:', err.message);
    process.exit(1);
  }
}

testFileUpload();
