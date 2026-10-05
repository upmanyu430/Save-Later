import 'package:metadata_fetch/metadata_fetch.dart';
void main() async {
  try {
    var data = await MetadataFetch.extract('omarchy.org');
    print('Image: ' + (data?.image ?? 'null'));
  } catch (e) { print('Error: ' + e.toString()); }
}

