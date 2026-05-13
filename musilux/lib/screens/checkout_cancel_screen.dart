import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CheckoutCancelScreen extends StatelessWidget {
  const CheckoutCancelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago cancelado')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel_outlined, size: 96, color: AppColors.error),
            SizedBox(height: 18),
            Text(
              'Pago cancelado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('No se realizó el cobro. Puedes intentarlo de nuevo.'),
          ],
        ),
      ),
    );
  }
}
