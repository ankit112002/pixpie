import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/api_provider.dart';

class UnassignedAoiScreen extends StatefulWidget {
  const UnassignedAoiScreen({super.key});

  @override
  State<UnassignedAoiScreen> createState() =>
      _UnassignedAoiScreenState();
}

class _UnassignedAoiScreenState
    extends State<UnassignedAoiScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<ApiProvider>().getUnAssignedAoi());
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case "HIGH":
        return Colors.red;
      case "MEDIUM":
        return Colors.orange;
      case "LOW":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "DRAFT":
        return Colors.blue;
      case "SUBMITTED":
        return Colors.deepPurple;
      case "CLOSED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Unassigned AOI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<ApiProvider>(
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style:
                const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.unassignedAoi.isEmpty) {
            return const Center(
              child: Text(
                "No Unassigned AOI Found",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.getUnAssignedAoi(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
              provider.unassignedAoi.length,
              itemBuilder: (context, index) {

                final aoi =
                provider.unassignedAoi[index];

                final isRequested = provider
                    .requestedAoiIds
                    .contains(aoi["id"]);

                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 16),
                  padding:
                  const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset:
                        const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      /// Header Row
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              aoi["aoi_name"] ??
                                  "",
                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                          ),
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                                horizontal:
                                10,
                                vertical:
                                5),
                            decoration:
                            BoxDecoration(
                              color: _priorityColor(
                                  aoi[
                                  "priority"])
                                  .withOpacity(
                                  0.1),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  20),
                            ),
                            child: Text(
                              aoi["priority"] ??
                                  "",
                              style:
                              TextStyle(
                                color: _priorityColor(
                                    aoi[
                                    "priority"]),
                                fontWeight:
                                FontWeight
                                    .w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Code: ${aoi["aoi_code"] ?? ""}",
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                              Icons.location_on,
                              size: 18,
                              color:
                              Colors.grey),
                          const SizedBox(
                              width: 6),
                          Expanded(
                            child: Text(
                              "${aoi["city"]}, ${aoi["state"]}",
                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                                horizontal:
                                10,
                                vertical:
                                5),
                            decoration:
                            BoxDecoration(
                              color: _statusColor(
                                  aoi[
                                  "status"])
                                  .withOpacity(
                                  0.1),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  20),
                            ),
                            child: Text(
                              aoi["status"] ??
                                  "",
                              style:
                              TextStyle(
                                color: _statusColor(
                                    aoi[
                                    "status"]),
                                fontWeight:
                                FontWeight
                                    .w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            "${aoi["center_latitude"]}, ${aoi["center_longitude"]}",
                            style:
                            TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// Request Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            isRequested
                                ? Colors
                                .grey
                                : null,
                            padding:
                            const EdgeInsets
                                .symmetric(
                                vertical:
                                12),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  10),
                            ),
                          ),
                          onPressed: isRequested
                              ? null
                              : () =>
                              _showRequestBottomSheet(
                                context,
                                aoi["id"],
                              ),
                          child: Text(
                            isRequested
                                ? "REQUESTED"
                                : "Request This AOI",
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showRequestBottomSheet(
      BuildContext context, String aoiId) {

    final TextEditingController
    notesController =
    TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom +
                20,
          ),
          child: Consumer<ApiProvider>(
            builder:
                (context, provider, child) {
              return Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    "Request This AOI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 15),
                  TextField(
                    controller:
                    notesController,
                    maxLines: 3,
                    decoration:
                    const InputDecoration(
                      hintText:
                      "Why do you want to work on this area?",
                      border:
                      OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(
                      height: 20),
                  SizedBox(
                    width:
                    double.infinity,
                    child:
                    ElevatedButton(
                      onPressed:
                      provider
                          .isLoading
                          ? null
                          : () async {
                        final success =
                        await provider
                            .requestAoi(
                          aoiId:
                          aoiId,
                          requestNotes:
                          notesController
                              .text
                              .trim(),
                        );
                        Navigator.pop(
                            context);
                        if (success) {
                          ScaffoldMessenger
                              .of(
                              context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Request Sent Successfully"),
                            ),
                          );
                        }
                      },
                      child: provider
                          .isLoading
                          ? const SizedBox(
                        height:
                        18,
                        width:
                        18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color: Colors
                              .white,
                        ),
                      )
                          : const Text(
                          "Submit Request"),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}