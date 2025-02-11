import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<String> contacts = [];
  List<bool> selectedContacts = [];

  void _showAddContactDialog() {
    TextEditingController contactController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Contact'),
            content: TextField(controller: contactController, decoration: InputDecoration(hintText: 'Enter contact name')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (contactController.text.isNotEmpty) {
                    setState(() {
                      contacts.add(contactController.text);
                      selectedContacts.add(false); // Add default checkbox state
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _splitContacts() {
    final selected = contacts.asMap().entries.where((entry) => selectedContacts[entry.key]).map((entry) => entry.value).toList();

    Navigator.push(context, MaterialPageRoute(builder: (context) => SelectedContactsScreen(selectedContacts: selected)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedContacts.where((isSelected) => isSelected).length;

    return Scaffold(
      appBar: AppBar(title: Text('Contacts'), centerTitle: true),
      body:
          contacts.isEmpty
              ? Center(child: Text('No contacts added yet.', style: TextStyle(fontSize: 20)))
              : ListView.builder(
                itemCount: contacts.length,
                itemBuilder:
                    (context, index) => ListTile(
                      leading: Icon(Icons.person),
                      title: Text(contacts[index]),
                      trailing: Checkbox(
                        value: selectedContacts[index],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedContacts[index] = value ?? false;
                          });
                        },
                      ),
                    ),
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (selectedCount >= 2) ElevatedButton(onPressed: _splitContacts, child: Text('Split Contacts')),
          SizedBox(height: 10),
          FloatingActionButton(onPressed: _showAddContactDialog, child: Icon(Icons.add)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class SelectedContactsScreen extends StatefulWidget {
  final List<String> selectedContacts;

  SelectedContactsScreen({required this.selectedContacts});

  @override
  _SelectedContactsScreenState createState() => _SelectedContactsScreenState();
}

class _SelectedContactsScreenState extends State<SelectedContactsScreen> with SingleTickerProviderStateMixin {
  TextEditingController noteController = TextEditingController();
  TextEditingController totalAmountController = TextEditingController();

  // You can set your initial value for total amount here
  late List<bool> isSelected;
  late double amountPerContact;
  late List<int> counters;
  late List<double> percentages;
  late List<double> amounts;
  late List<bool> isRedistributed;

  double totalAmount = 0; // Declare percentages list
  List<double> manualAmounts = [];
  List<bool> isManuallyAssigned = [];
  List<bool> isManuallyAssignedper = [];
  // List to store calculated amounts

  // New list to store percentage for each contact

  @override
  void incrementCounter(int index) {
    setState(() {
      counters[index]++;
      updateAmountPerContact(); // Recalculate the amount per contact
    });
  }

  void decrementCounter(int index) {
    setState(() {
      if (counters[index] > 1) {
        counters[index]--;
        updateAmountPerContact(); // Recalculate the amount per contact
      }
    });
  }

  void initState() {
    super.initState();
    isSelected = List<bool>.filled(widget.selectedContacts.length, true);
    isRedistributed = List<bool>.filled(widget.selectedContacts.length, false);
    counters = List<int>.filled(widget.selectedContacts.length, 1); // Initialize the counters with 1 for each contact
    amountPerContact = totalAmount / widget.selectedContacts.length;
    // totalAmountController.text = totalAmount.toString();
    manualAmounts = List.filled(widget.selectedContacts.length, 0.0);
    isManuallyAssigned = List.filled(widget.selectedContacts.length, false);
    isManuallyAssignedper = List.filled(widget.selectedContacts.length, false);
    percentages = List<double>.filled(widget.selectedContacts.length, 0.0);
    amounts = List<double>.filled(widget.selectedContacts.length, 0.0); // Initialize amounts
    // Initialize percentages
  }

  double get remainingAmount {
    double assignedAmount = manualAmounts.fold(0, (sum, value) => sum + value);
    return totalAmount - assignedAmount;
  }

  double get autoAssignAmount {
    int unassignedCount = isManuallyAssignedper.where((isSet) => !isSet).length;
    return unassignedCount > 0 ? remainingAmount / unassignedCount : 0;
  }

  // Function to calculate amount per contact based on selected contacts
  void updateAmountPerContact() {
    int totalCounters = 0;

    // Sum of counters only for selected contacts
    for (int i = 0; i < widget.selectedContacts.length; i++) {
      if (isSelected[i]) {
        totalCounters += counters[i];
      }
    }

    if (totalCounters > 0) {
      setState(() {
        for (int i = 0; i < widget.selectedContacts.length; i++) {
          if (isSelected[i]) {
            // Distribute based on counters (only among selected users)
            amountPerContact = (totalAmount * counters[i]) / totalCounters;
          } else {
            amountPerContact = 0; // If unselected, no amount assigned
          }
        }
      });
    } else {
      setState(() {
        amountPerContact = 0; // No one selected
      });
    }
  }

  void updateRemainingPercentages() {
    double assignedPercentage = 0;

    // Calculate total manually assigned percentages
    for (int i = 0; i < widget.selectedContacts.length; i++) {
      if (isManuallyAssignedper[i]) {
        assignedPercentage += percentages[i];
      }
    }

    double remainingPercentage = 100 - assignedPercentage;

    // Find selected contacts without a manually assigned percentage
    List<int> unassignedIndexes = [];
    for (int i = 0; i < widget.selectedContacts.length; i++) {
      if (isSelected[i] && !isManuallyAssignedper[i]) {
        unassignedIndexes.add(i);
      }
    }

    double autoPercentage = unassignedIndexes.isNotEmpty ? remainingPercentage / unassignedIndexes.length : 0;

    setState(() {
      for (int i in unassignedIndexes) {
        percentages[i] = autoPercentage;
      }
    });

    updateAmounts();
  }

  void updateAmounts() {
    setState(() {
      for (int i = 0; i < widget.selectedContacts.length; i++) {
        if (isSelected[i]) {
          amounts[i] = (percentages[i] / 100) * totalAmount;
        } else {
          amounts[i] = 0; // No auto-assignment
        }
      }
    });
  }

  void toggleSelection(int index) {
    setState(() {
      isSelected[index] = !isSelected[index]; // Toggle selection

      if (!isSelected[index]) {
        // If toggled off, set its amount to 0 but don't reset others
        double amountToRedistribute = amounts[index];
        amounts[index] = 0; // Set deselected amount to 0
        percentages[index] = 0; // Reset percentage for deselected item
        isManuallyAssignedper[index] = false; // Reset manual assignment flag

        // Count remaining selected contacts
        int remainingContacts = isSelected.where((selected) => selected).length;

        if (remainingContacts > 0) {
          double redistributedAmount = amountToRedistribute / remainingContacts;

          for (int i = 0; i < widget.selectedContacts.length; i++) {
            if (isSelected[i]) {
              amounts[i] += redistributedAmount; // Redistribute amount to only selected users
            }
          }
        }
      }

      updateRemainingPercentages(); // Ensure percentages update correctly
      updateAmountPerContact(); // Recalculate amounts
    });
  }

  // Function to calculate amounts based on percentage input

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Total", style: TextStyle(fontSize: 30)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("₹", style: TextStyle(fontSize: 30)),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: totalAmountController,
                      decoration: InputDecoration(hintText: "0"),

                      onChanged: (value) {
                        setState(() {
                          totalAmount = double.tryParse(value) ?? 0;
                          updateAmountPerContact(); // Recalculate per contact amount
                          // totalAmountController.text = totalAmount.toString();
                        });
                      }, // Centers the hint text

                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                height: 45,
                width: 140,
                padding: EdgeInsets.all(2),
                child: TextField(
                  keyboardType: TextInputType.text,
                  controller: noteController,
                  textAlignVertical: TextAlignVertical.center,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  maxLines: null,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    hintText: "What's this for?",
                    hintStyle: TextStyle(fontWeight: FontWeight.bold),
                    fillColor: Colors.black12,
                    counterText: "",
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 22),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(8, 8)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(8, 8)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.group)),
                  Tab(icon: Icon(Icons.abc)),
                  Tab(icon: Icon(Icons.supervised_user_circle_rounded)),
                  Tab(icon: Icon(Icons.percent)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 35, top: 20),
                child: Align(alignment: Alignment.bottomLeft, child: Text("Split Evenly", style: TextStyle(fontSize: 20))),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1
                    ListView.builder(
                      padding: EdgeInsets.only(top: 0),
                      itemCount: widget.selectedContacts.length,
                      itemBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    toggleSelection(index); // Toggle selection on tap
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected[index] ? Colors.green : Colors.grey,
                                    child: Icon(size: 20, isSelected[index] ? Icons.check : Icons.close, color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                CircleAvatar(radius: 20),
                                SizedBox(width: 10),
                                Text(widget.selectedContacts[index], style: TextStyle(fontSize: 18)),
                                Spacer(),
                                // Display ₹0.00 for unselected contacts, else the amount per contact
                                Text(isSelected[index] ? "₹${amountPerContact.toStringAsFixed(2)}" : "₹0.00", style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                    ),
                    // Tab 2 content (another widget or the same, adjust as needed)
                    ListView.builder(
                      padding: EdgeInsets.only(top: 0),
                      itemCount: widget.selectedContacts.length,
                      itemBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    toggleSelection(index); // Toggle selection on tap
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected[index] ? Colors.green : Colors.grey,
                                    child: Icon(size: 20, isSelected[index] ? Icons.check : Icons.close, color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                CircleAvatar(radius: 20),
                                SizedBox(width: 10),
                                Text(widget.selectedContacts[index], style: TextStyle(fontSize: 18)),
                                Spacer(),

                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    textAlign: TextAlign.end,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value.isNotEmpty) {
                                          manualAmounts[index] = double.tryParse(value) ?? 0.0;
                                          isManuallyAssignedper[index] = true;
                                        } else {
                                          manualAmounts[index] = 0.0;
                                          isManuallyAssignedper[index] = false;
                                        }
                                        updateAmountPerContact();
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          isSelected[index]
                                              ? "₹${isManuallyAssignedper[index] ? manualAmounts[index].toStringAsFixed(2) : autoAssignAmount.toStringAsFixed(2)}"
                                              : "00",
                                    ),
                                  ),
                                ),

                                // Text(isSelected[index] ? "₹${amountPerContact.toStringAsFixed(2)}" : "₹0.00", style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                    ),
                    // Tab 3 content (similar to Tab 1, can be another set of views)
                    ListView.builder(
                      padding: EdgeInsets.only(top: 0),
                      itemCount: widget.selectedContacts.length,
                      itemBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    toggleSelection(index); // Toggle selection on tap
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected[index] ? Colors.green : Colors.grey,
                                    child: Icon(size: 20, isSelected[index] ? Icons.check : Icons.close, color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                CircleAvatar(radius: 20),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.selectedContacts[index], style: TextStyle(fontSize: 18)),
                                    isSelected[index]
                                        ? Text("₹${(amountPerContact * counters[index]).toStringAsFixed(2)}", style: TextStyle(fontSize: 20))
                                        : Container(),
                                  ],
                                ),

                                // Update the price based on the counter
                                Spacer(),
                                isSelected[index]
                                    ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(child: IconButton(onPressed: () => decrementCounter(index), icon: Icon(Icons.remove))),

                                        SizedBox(width: 10),
                                        Text("${counters[index]}"),
                                        SizedBox(width: 10),

                                        CircleAvatar(child: IconButton(onPressed: () => incrementCounter(index), icon: Icon(Icons.add))),
                                      ],
                                    )
                                    : Container(),
                              ],
                            ),
                          ),
                    ),

                    // Tab 4 content: Percentage
                    ListView.builder(
                      padding: EdgeInsets.only(top: 0),
                      itemCount: widget.selectedContacts.length,
                      itemBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    toggleSelection(index); // Toggle selection on tap
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected[index] ? Colors.green : Colors.grey,
                                    child: Icon(size: 20, isSelected[index] ? Icons.check : Icons.close, color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                CircleAvatar(radius: 20),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.selectedContacts[index], style: TextStyle(fontSize: 18)),
                                    Text("₹${amounts[index].toStringAsFixed(2)}", style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                                Spacer(),
                                isSelected[index]
                                    ? SizedBox(
                                      width: 60,
                                      child: TextField(
                                        keyboardType: TextInputType.number,

                                        onChanged: (value) {
                                          setState(() {
                                            if (value.isNotEmpty) {
                                              percentages[index] = double.tryParse(value) ?? 0.0;
                                              isManuallyAssignedper[index] = true;
                                            } else {
                                              percentages[index] = 0.0;
                                              isManuallyAssignedper[index] = false;
                                            }
                                            updateRemainingPercentages(); // Update remaining unassigned percentages
                                          });
                                        },

                                        decoration: InputDecoration(
                                          hintText:
                                              percentages[index] > 0
                                                  ? "${percentages[index].toStringAsFixed(2)}%"
                                                  : "0%", // Always shows the last entered value
                                        ),
                                      ),
                                    )
                                    : Text("₹0.00", style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: () {}, child: Text("Send request")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
