import 'package:flutter/material.dart';

class LoadingFallbackWidget extends StatefulWidget {
  final bool isLoading;
  final bool hasData;
  final Widget child;
  final String fallbackMessage;
  final String? fallbackIcon;
  final VoidCallback? onReload;
  final Duration loadingDuration;

  const LoadingFallbackWidget({
    super.key,
    required this.isLoading,
    required this.hasData,
    required this.child,
    this.fallbackMessage = 'No data available',
    this.fallbackIcon,
    this.onReload,
    this.loadingDuration = const Duration(seconds: 3),
  });

  @override
  State<LoadingFallbackWidget> createState() => _LoadingFallbackWidgetState();
}

class _LoadingFallbackWidgetState extends State<LoadingFallbackWidget> {
  bool showReloadButton = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
      _startLoadingTimer();
    }
  }

  @override
  void didUpdateWidget(LoadingFallbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      setState(() {
        showReloadButton = false;
      });
      _startLoadingTimer();
    }
  }

  void _startLoadingTimer() {
    Future.delayed(widget.loadingDuration, () {
      if (mounted && widget.isLoading) {
        setState(() {
          showReloadButton = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      if (showReloadButton) {
        return _buildReloadButton();
      } else {
        return _buildLoadingSpinner();
      }
    }

    if (!widget.hasData) {
      return _buildFallbackMessage();
    }

    return widget.child;
  }

  Widget _buildLoadingSpinner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReloadButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Server not connected',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap to reload',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onReload,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Reload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.fallbackIcon != null
                ? IconData(int.parse(widget.fallbackIcon!),
                    fontFamily: 'MaterialIcons')
                : Icons.info_outline_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            widget.fallbackMessage,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onReload != null) ...[
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onReload,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Reload'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
