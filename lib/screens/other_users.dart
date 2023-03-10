import 'package:fairsplit/screens/add_transaction.dart';
import 'package:flutter/material.dart';

import '../models/other_user.dart';
import '../screens/add_other_user.dart';
import '../shared/lists.dart';
import '../shared/parameters.dart';
import '../widgets/widget.dart';

class OtherUsers extends StatefulWidget {
  const OtherUsers({Key? key}) : super(key: key);

  @override
  State<OtherUsers> createState() => _OtherUsersState();
}

class _OtherUsersState extends State<OtherUsers> {
  List<OtherUser> allUsers = [], users = [];
  var userNames = <String>{};
  bool isloading = true;
  String _search = '';
  String _type = 'tout';
  int? _sortColumnIndex = 1;
  bool _isAscending = true;
  TextEditingController _controller = TextEditingController();

  void _newUser(BuildContext context, OtherUser user) async =>
      await createDialog(context, AddOtherUser(user: user), false);

  void loadData() async {
    var res = await sqlQuery(selectUrl, {'sql1': 'SELECT * FROM OtherUsers;'});
    var dataUsers = res[0];

    for (var ele in dataUsers) {
      allUsers.add(OtherUser(
        userId: int.parse(ele['userId']),
        name: ele['name'],
        type: ele['type'],
        joinDate: DateTime.parse(ele['joinDate']),
        phone: ele['phone'],
        amount: double.parse(ele['amount']),
        rest: double.parse(ele['rest']),
      ));

      userNames.add(ele['name']);
    }

    setState(() {
      isloading = false;
    });
  }

  void filterUsers() {
    users.clear();
    for (var user in allUsers) {
      if ((_search.isEmpty || user.name == _search) && (_type == 'tout' || user.type == _type)) users.add(user);
    }

    onSort();
  }

  void onSort() {
    switch (_sortColumnIndex) {
      case 1:
        users.sort((a, b) => _isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 5:
        users.sort((a, b) => _isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
        break;
      case 6:
        users.sort((a, b) => _isAscending ? a.rest.compareTo(b.rest) : b.rest.compareTo(a.rest));
        break;
    }
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    filterUsers();

    List<DataColumn> columns = [
      dataColumn(context, ''),
      sortableDataColumn(
        context,
        getText('name'),
        (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _isAscending = ascending;
        }),
      ),
      ...[getText('joinDate'), getText('phone'), getText('type')].map((e) => dataColumn(context, e)),
      ...[getText('amount'), getText('rest')].map((e) => sortableDataColumn(
            context,
            e,
            (columnIndex, ascending) => setState(() {
              _sortColumnIndex = columnIndex;
              _isAscending = ascending;
            }),
          )),
      dataColumn(context, ''),
    ];

    List<DataRow> rows = users
        .map((user) => DataRow(
              onSelectChanged: (value) async => await createDialog(
                context,
                AddTransaction(
                  sourceTab: 'ou',
                  userId: user.userId,
                  selectedName: user.name,
                  type: user.type,
                  amount: user.amount,
                  rest: user.rest,
                  selectedTransactionType: user.type == 'loan' ? 2 : 3,
                ),
                false,
              ),
              cells: [
                dataCell(context, (users.indexOf(user) + 1).toString()),
                dataCell(context, user.name, textAlign: TextAlign.start),
                dataCell(context, myDateFormate.format(user.joinDate)),
                dataCell(context, user.phone),
                dataCell(context, getText(user.type)),
                dataCell(context, myCurrency.format(user.amount), textAlign: TextAlign.end),
                dataCell(context, myCurrency.format(user.rest), textAlign: TextAlign.end),
                DataCell(IconButton(
                  onPressed: () => _newUser(context, user),
                  hoverColor: Colors.transparent,
                  icon: Icon(Icons.edit, size: 22, color: winTileColor),
                )),
              ],
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _newUser(context, OtherUser()),
        tooltip: getText('newUser'),
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 3.0,
                ),
              ],
            ),
            child: Column(children: [
              const SizedBox(width: double.minPositive, height: 8.0),
              searchBar(),
              const SizedBox(width: double.minPositive, height: 8.0),
              SizedBox(width: getWidth(context, .20), child: const Divider()),
              const SizedBox(width: double.minPositive, height: 8.0),
              Expanded(
                child: isloading
                    ? myPogress()
                    : users.isEmpty
                        ? SizedBox(width: getWidth(context, .45), child: emptyList())
                        : users.isEmpty
                            ? emptyList()
                            : SingleChildScrollView(
                                child: dataTable(
                                  isAscending: _isAscending,
                                  sortColumnIndex: _sortColumnIndex,
                                  columns: columns,
                                  rows: rows,
                                ),
                              ),
              ),
            ]),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget searchBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('name'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              height: getHeight(context, textFeildHeight),
              width: getWidth(context, .22),
              child: Autocomplete<String>(
                onSelected: (item) => setState(() {
                  _search = item;
                }),
                optionsBuilder: (textEditingValue) {
                  return userNames.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                fieldViewBuilder: (
                  context,
                  textEditingController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  _controller = textEditingController;
                  return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _controller.text.isEmpty ? Colors.grey : winTileColor),
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: TextFormField(
                        controller: _controller,
                        focusNode: focusNode,
                        style: const TextStyle(fontSize: 18.0),
                        onChanged: ((value) => setState(() {})),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                          hintText: getText('search'),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20.0),
                          suffixIcon: textEditingController.text.isEmpty
                              ? const SizedBox()
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      textEditingController.clear();
                                      _search = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 20.0)),
                        ),
                      ));
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8.0,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: getHeight(context, .2), maxWidth: getWidth(context, .22)),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                child: myText(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getText('type'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            myDropDown(
              context,
              value: _type,
              color: _type == 'tout' ? Colors.grey : winTileColor,
              items: otherUsersTypesSearch.entries.map((item) {
                return DropdownMenuItem(
                  value: getKeyFromValue(item.value),
                  alignment: AlignmentDirectional.center,
                  child: Text(item.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => _type = value.toString()),
            ),
          ],
        ),
        const SizedBox(width: 8.0),
        (_controller.text.isNotEmpty || _type != 'tout')
            ? IconButton(
                onPressed: () => setState(() {
                  _search = '';
                  _controller.clear();
                  _type = 'tout';
                }),
                icon: Icon(
                  Icons.update,
                  color: winTileColor,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
