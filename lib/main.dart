import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'album.dart';

void main() => runApp(const ScrollApp());

class ScrollApp extends StatelessWidget {
  const ScrollApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ScrollHome(),
    );
  }
}

class ScrollHome extends StatefulWidget {
  const ScrollHome({Key? key}) : super(key: key);

  @override
  State<ScrollHome> createState() => _ScrollHomeState();
}

class _ScrollHomeState extends State<ScrollHome> {
  static const _pageSize = 20;

  final PagingController<int, Album> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    _pagingController.addStatusListener((status) {
      if (status == PagingStatus.subsequentPageError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Something went wrong while fetching a new page.',
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _pagingController.retryLastFailedRequest(),
            ),
          ),
        );
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: RefreshIndicator(
          onRefresh: () => Future.sync(
            () => _pagingController.refresh(),
          ),
          child: PagedListView<int, Album>.separated(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<Album>(
              animateTransitions: true,
              itemBuilder: (context, album, index) => TextButton(
                onPressed: () {
                  SnackBar snackBar = SnackBar(
                    content: Text('Cê pressionou o album ${album.id}'),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                child: ListTile(
                  leading: Text('${album.id}'),
                  title: Text(album.title),
                ),
              ),
            ),
            separatorBuilder: (context, index) => const Divider(),
          ),
        ),
      );

  Future<void> _fetchPage(pageKey) async {
    final newItems = await fetchAlbum(pageKey, _pageSize);
    final isLastPage = newItems.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(newItems);
    } else {
      final nextPageKey = pageKey + newItems.length;
      _pagingController.appendPage(newItems, nextPageKey);
    }
  }
}

Future<List<Album>> fetchAlbum(init, length) async {
  String query =
      List.generate(length, (index) => '&id=${init + index + 1}').join('');
  final response = await http
      .get(Uri.parse('https://jsonplaceholder.typicode.com/albums?$query'));

  if (response.statusCode == 200) {
    List<dynamic> listAlbuns = jsonDecode(response.body);
    return List.generate(
        listAlbuns.length, (index) => Album.fromJson(listAlbuns[index]));
  } else {
    throw Exception('Failed to load album');
  }
}
