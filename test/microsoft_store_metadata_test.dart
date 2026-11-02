// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:metadata_fetch/metadata_fetch.dart';

void main() {
  test('fetch metadata with browser headers for Microsoft Store URL', () async {
    const url = 'https://apps.microsoft.com/detail/9pj5b1hxnskv?ocid=webpdpshare&hl=en-US&gl=IN';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );

    print('Response status: ${response.statusCode}');
    expect(response.statusCode, 200);

    final document = parser.parse(utf8.decode(response.bodyBytes, allowMalformed: true));
    final metadata = MetadataParser.parse(document, url: url);

    print('Metadata title: "${metadata.title}"');
    print('Metadata description: "${metadata.description?.substring(0, 50)}..."');
    print('Metadata image: "${metadata.image}"');

    expect(metadata.image, isNotNull);
    expect(metadata.image, contains('store-images.s-microsoft.com'));
    expect(metadata.title, contains('Vayli'));
  });
}
