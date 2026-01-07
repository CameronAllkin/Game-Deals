import 'dart:convert';
import 'package:http/http.dart' as http;

class CheapSharkAPI{
  final String _baseURL = "https://www.cheapshark.com/api/1.0/";
  static final int rateLimit = 100;
  static final Map<String, List<String>> stores = {
    "1": ["Steam", "https://store.steampowered.com/"],
    "2": ["Gamers Gate", "https://www.gamersgate.com/"],
    "3": ["Green Man Gaming", "https://www.greenmangaming.com/"],
    "7": ["GOG", "https://www.gog.com/en"],
    "8": ["Origin", "https://www.ea.com/games"],
    "11": ["Humble", "https://www.humblebundle.com/games"],
    "13": ["Ubisoft", "https://store.ubisoft.com/anz/home?lang=en_AU"],
    "15": ["Fanatical", "https://www.fanatical.com/en/"],
    "21": ["Win Game Store", "https://www.wingamestore.com/"],
    "23": ["Game Billet", "https://www.gamebillet.com/"],
    "24": ["Voidu", "https://www.voidu.com/en/"],
    "25": ["Epic Games", "https://store.epicgames.com/en-US/"],
    "27": ["Games Planet", "https://us.gamesplanet.com/"],
    "29": ["2Game", "https://2game.com/en_au/"],
    "31": ["Blizzard", "https://www.blizzard.com/en-us/"],
    "33": ["DLGamer", "https://www.dlgamer.com/us/"],
    "34": ["Noctre", "https://www.noctre.com/"],
    "35": ["Dream Game", "https://www.dreamgame.com/en/"]
  };



  Future<Map<String, dynamic>> getGame(String id) async {
    final url = "${_baseURL}games?id=${id}";
    final response = await http.get(Uri.parse(url));
    final decode = jsonDecode(response.body);
    decode["id"] = id;
    return decode;
  }

  Future<List<Map<String, dynamic>>> searchGames(String title, List<String> sStores, {int pages = 3}) async {
    List<Map<String, dynamic>> out = [];
    for(int i = 0; i < pages; i++){
      final url = "${_baseURL}deals?title=${title}&storeID=${sStores.toList().join(",")}&sortBy=reviews&pageNumber=${i}";
      final response = await http.get(Uri.parse(url));
      final decode = jsonDecode(response.body);
      if(decode.length == 0){
        break;
      }
      for(final r in decode as Iterable){
        out.add(r);
      }
    }
    return out;
  } 

  Future<List<Map<String, dynamic>>> getDeals(List<String> sStores, {int pages = 3}) async {
    List<Map<String, dynamic>> out = [];
    for(int i = 0; i < pages; i++){
      final url = "${_baseURL}deals?storeID=${sStores.toList().join(",")}&pageNumber=${i}";
      final response = await http.get(Uri.parse(url));
      final decode = jsonDecode(response.body);
      if(decode.length == 0){
        break;
      }
      for(final r in decode as Iterable){
        out.add(r);
      }
    }
    return out;
  }






  static List<String> searchGameToList(Map<String, dynamic> game){
    final id = game["gameID"];
    final title = game["title"];
    final store = CheapSharkAPI.stores[game["storeID"]]![0];
    final sale = game["isOnSale"];
    final salePrice = "\$${CheapSharkAPI.convertAUD(double.parse(game["salePrice"])).toStringAsFixed(2)}";
    final normalPrice = "\$${CheapSharkAPI.convertAUD(double.parse(game["normalPrice"])).toStringAsFixed(2)}";
    final discount = "${(100-double.parse(game["salePrice"])/double.parse(game["normalPrice"])*100).toStringAsFixed(0)}%";
    final img = game["thumb"];
    return [id, title, store, sale, salePrice, normalPrice, discount, img];
  }

  static List<Map<String, dynamic>> searchGameSort(List<Map<String, dynamic>> games){
    games.sort((a, b){
      final at = a["title"].toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ');
      final bt = b["title"].toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ');
      final tlc = at.compareTo(bt);
      if (tlc == 0){
        final ap = double.parse(a["salePrice"]);
        final bp = double.parse(b["salePrice"]);
        return ap.compareTo(bp);
      }
      return tlc;
    });
    return games;
  }

  static List<Map<String, dynamic>> searchGameFilter(List<Map<String, dynamic>> games){
    List<String> titles = [];
    List<Map<String, dynamic>> out = [];

    for(Map<String, dynamic> game in games){
      if(!titles.contains(game["title"])){
        titles.add(game["title"]);
        out.add(game);
      }
    }

    return out;
  }





  static List<dynamic> gameListToList(Map<String, dynamic> game, List<String> sStores){
    final id = game["id"];
    final title = game["info"]["title"];
    final deals = dealList(game["deals"], sStores);
    final best = deals[0][1];
    final cheapest = convertAUD(double.parse(game["cheapestPriceEver"]["price"]));
    final img = game["info"]["thumb"];
    return [id, title, deals, best, cheapest, img];
  }

  static List<List<dynamic>> dealList(List<dynamic> deals, List<String> sStores){
    deals.sort((a, b) => int.parse(a["storeID"]).compareTo(int.parse(b["storeID"])));
    final List<List<dynamic>> dealList = [];
    for(final deal in deals){
      if(sStores.contains(deal["storeID"].toString())){
        final redirect = "https://www.cheapshark.com/redirect?dealID=${deal["dealID"]}";
        final store = List.from(stores[deal["storeID"]]??["", ""]);
        store.add(redirect);
        final price = convertAUD(double.parse(deal["price"]));
        final retail = convertAUD(double.parse(deal["retailPrice"]));
        final discount = 100-(price/retail)*100;
        dealList.add([store, price, retail, discount]);
      }
    }
    dealList.sort((a, b) => a[1].compareTo(b[1]));
    return dealList;
  }

  static List<dynamic> gamesListSort(List<dynamic> games, String method){
    switch(method){
      case "id": 
        games.sort((a, b) => int.parse(a[0]).compareTo(int.parse(b[0])));
        break;
      case "title": 
        games.sort((a, b) => a[1].compareTo(b[1]));
        break;
      case "price": 
        games.sort((a, b) => a[3].compareTo(b[3]));
        break;
      case "discount": 
        games.sort((a, b) => b[2][0][3].compareTo(a[2][0][3]));
        break;
      case "cheapest": 
        games.sort((a, b) => b[4].compareTo(a[4]));
        break;
    }
    return games;
  }






  static double convertAUD(double usd){
    return usd * 1.58;
  }
}

