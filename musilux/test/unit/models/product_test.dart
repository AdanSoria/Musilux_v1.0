import 'package:flutter_test/flutter_test.dart';
import 'package:musilux/models/product.dart';

void main() {
  group('ProductMedia', () {
    test('fromJson parsea todos los campos', () {
      final media = ProductMedia.fromJson({
        'id': '1',
        'url_archivo': 'https://example.com/img.jpg',
        'es_principal': true,
        'tipo_multimedia': 'imagen',
      });
      expect(media.id, '1');
      expect(media.urlArchivo, 'https://example.com/img.jpg');
      expect(media.esPrincipal, true);
      expect(media.tipoMultimedia, 'imagen');
    });

    test('fromJson interpreta es_principal=1 como true', () {
      final media = ProductMedia.fromJson({
        'id': '2',
        'url_archivo': '',
        'es_principal': 1,
        'tipo_multimedia': 'video',
      });
      expect(media.esPrincipal, true);
    });

    test('fromJson usa valores por defecto en campos ausentes', () {
      final media = ProductMedia.fromJson({});
      expect(media.id, '');
      expect(media.urlArchivo, '');
      expect(media.esPrincipal, false);
      expect(media.tipoMultimedia, 'imagen');
    });
  });

  group('ProductCategory', () {
    test('fromJson parsea correctamente', () {
      final cat = ProductCategory.fromJson({
        'id': '1',
        'nombre': 'Instrumentos',
        'slug': 'instrumentos',
      });
      expect(cat.id, '1');
      expect(cat.nombre, 'Instrumentos');
      expect(cat.slug, 'instrumentos');
    });

    test('fromJson usa cadena vacía en campos ausentes', () {
      final cat = ProductCategory.fromJson({});
      expect(cat.id, '');
      expect(cat.nombre, '');
      expect(cat.slug, '');
    });
  });

  group('ProductTag', () {
    test('fromJson parsea correctamente', () {
      final tag = ProductTag.fromJson({'id': '5', 'nombre': 'Guitarra'});
      expect(tag.id, '5');
      expect(tag.nombre, 'Guitarra');
    });

    test('fromJson usa cadena vacía en campos ausentes', () {
      final tag = ProductTag.fromJson({});
      expect(tag.id, '');
      expect(tag.nombre, '');
    });
  });

  group('Product.fromJson', () {
    Map<String, dynamic> validJson() => {
          'id': '42',
          'nombre': 'Guitarra Eléctrica',
          'precio': 1299.99,
          'slug': 'guitarra-electrica',
          'inventario': 5,
          'esta_activo': true,
          'descripcion': 'Guitarra de alta calidad',
          'tipo_producto': 'fisico',
          'id_categoria': '1',
          'bpm': null,
          'multimedia': [],
          'categoria': {
            'id': '1',
            'nombre': 'Instrumentos',
            'slug': 'instrumentos',
          },
          'etiquetas': [],
        };

    test('parsea todos los campos principales', () {
      final p = Product.fromJson(validJson());
      expect(p.id, '42');
      expect(p.nombre, 'Guitarra Eléctrica');
      expect(p.precio, 1299.99);
      expect(p.slug, 'guitarra-electrica');
      expect(p.inventario, 5);
      expect(p.estaActivo, true);
      expect(p.descripcion, 'Guitarra de alta calidad');
      expect(p.tipoProducto, 'fisico');
      expect(p.idCategoria, '1');
      expect(p.categoria?.nombre, 'Instrumentos');
    });

    test('usa valores por defecto cuando faltan campos obligatorios', () {
      final p = Product.fromJson({});
      expect(p.id, '0');
      expect(p.nombre, 'Sin título');
      expect(p.precio, 0.0);
      expect(p.estaActivo, false);
      expect(p.tipoProducto, 'fisico');
    });

    test('los campos opcionales son null cuando están ausentes', () {
      final p = Product.fromJson({'id': '1', 'nombre': 'Test', 'precio': 100.0});
      expect(p.descripcion, isNull);
      expect(p.categoria, isNull);
      expect(p.bpm, isNull);
      expect(p.multimedia, isEmpty);
      expect(p.etiquetas, isEmpty);
    });

    test('interpreta esta_activo=1 como true', () {
      final json = validJson();
      json['esta_activo'] = 1;
      expect(Product.fromJson(json).estaActivo, true);
    });

    test('parsea bpm como entero', () {
      final json = validJson();
      json['bpm'] = 120;
      expect(Product.fromJson(json).bpm, 120);
    });

    test('parsea lista de multimedia', () {
      final json = validJson();
      json['multimedia'] = [
        {
          'id': '1',
          'url_archivo': 'https://img.com/a.jpg',
          'es_principal': true,
          'tipo_multimedia': 'imagen',
        },
      ];
      final p = Product.fromJson(json);
      expect(p.multimedia.length, 1);
      expect(p.multimedia.first.esPrincipal, true);
    });

    test('parsea lista de etiquetas', () {
      final json = validJson();
      json['etiquetas'] = [
        {'id': '1', 'nombre': 'Rock'},
      ];
      final p = Product.fromJson(json);
      expect(p.etiquetas.length, 1);
      expect(p.etiquetas.first.nombre, 'Rock');
    });

    test('precio como entero se convierte a double', () {
      final p = Product.fromJson({'id': '1', 'nombre': 'Test', 'precio': 500});
      expect(p.precio, 500.0);
      expect(p.precio, isA<double>());
    });
  });

  group('Product.imageUrl', () {
    test('retorna placeholder cuando no hay multimedia', () {
      final p = Product.fromJson({'id': '1', 'nombre': 'Test', 'precio': 0.0});
      expect(p.imageUrl, contains('placehold.co'));
    });

    test('retorna URL de la imagen marcada como principal', () {
      final p = Product.fromJson({
        'id': '1',
        'nombre': 'Test',
        'precio': 0.0,
        'multimedia': [
          {
            'id': '1',
            'url_archivo': 'https://img.com/secondary.jpg',
            'es_principal': false,
            'tipo_multimedia': 'imagen',
          },
          {
            'id': '2',
            'url_archivo': 'https://img.com/main.jpg',
            'es_principal': true,
            'tipo_multimedia': 'imagen',
          },
        ],
      });
      expect(p.imageUrl, 'https://img.com/main.jpg');
    });

    test('cae al primer elemento de imagen cuando ninguna es principal', () {
      final p = Product.fromJson({
        'id': '1',
        'nombre': 'Test',
        'precio': 0.0,
        'multimedia': [
          {
            'id': '1',
            'url_archivo': 'https://img.com/first.jpg',
            'es_principal': false,
            'tipo_multimedia': 'imagen',
          },
          {
            'id': '2',
            'url_archivo': 'https://img.com/second.jpg',
            'es_principal': false,
            'tipo_multimedia': 'imagen',
          },
        ],
      });
      expect(p.imageUrl, 'https://img.com/first.jpg');
    });
  });

  group('Product.toJson', () {
    test('serializa los campos del formulario correctamente', () {
      final p = Product.fromJson({
        'id': '42',
        'nombre': 'Guitarra',
        'precio': 1299.99,
        'slug': 'guitarra',
        'inventario': 5,
        'esta_activo': true,
        'descripcion': 'Desc',
        'tipo_producto': 'fisico',
        'id_categoria': '1',
        'multimedia': [],
        'etiquetas': [],
      });
      final result = p.toJson();
      expect(result['nombre'], 'Guitarra');
      expect(result['precio'], 1299.99);
      expect(result['id_categoria'], '1');
      expect(result['esta_activo'], true);
      expect(result['descripcion'], 'Desc');
    });
  });
}
