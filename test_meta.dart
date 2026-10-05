import 'package:metadata_fetch/metadata_fetch.dart';
void main() async {
  try {
    var data = await MetadataFetch.extract('https://omarchy.org');
    print('Title: ' + (data?.title ?? 'null'));
    print('Image: ' + (data?.image ?? 'null'));
    print('Desc: ' + (data?.description ?? 'null'));
  } catch (e) {
    print('Error: ' + e.toString());
  }
}

