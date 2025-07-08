import 'package:bloghub/presentation/edit_blog_screen/widgets/custom_input_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../theme/toast_helper.dart';

class EditBlogScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditBlogScreen({super.key, required this.post});

  @override
  State<EditBlogScreen> createState() => _EditBlogScreenState();
}

class _EditBlogScreenState extends State<EditBlogScreen> {
  late TextEditingController _titleController;
  late TextEditingController _excerptController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  final List<String> _categories = [
    'Technology',
    'Lifestyle',
    'Design',
    'Business',
    'Health',
    'Finance'
  ];

  late String _selectedCategory;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title']);
    _excerptController = TextEditingController(text: widget.post['excerpt']);
    _contentController = TextEditingController(text: widget.post['content']);
    _imageUrlController = TextEditingController(text: widget.post['imageUrl']);
    _selectedCategory = widget.post['category'] ?? 'Technology';
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('blog_posts')
          .doc(widget.post['id'])
          .update({
        'title': _titleController.text.trim(),
        'excerpt': _excerptController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ToastHelper.showSuccess(context, 'Post updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to update post');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Blog Post'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator.adaptive()
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomInputField(
                label: 'Title',
                controller: _titleController,
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                ),
              ),
              SizedBox(height: 2.h),
              CustomInputField(
                label: 'Excerpt',
                controller: _excerptController,
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              CustomInputField(
                label: 'Content',
                controller: _contentController,
                maxLines: 8,
              ),
              SizedBox(height: 2.h),
              CustomInputField(
                label: 'Image URL',
                controller: _imageUrlController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
