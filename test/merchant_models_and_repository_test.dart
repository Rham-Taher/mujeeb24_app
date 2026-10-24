import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

void main() {
  group('Phase 2 Merchant Models Unit Tests', () {
    test('DashboardOverview fromJson and toJson serialization', () {
      final json = {
        'open_conversations': 15,
        'waiting_human': 4,
        'new_customers': 20,
        'new_leads': 8,
        'transactions_needing_review': 3,
        'connections': {'whatsapp': 12, 'instagram': 3},
      };

      final overview = DashboardOverview.fromJson(json);
      expect(overview.openConversations, 15);
      expect(overview.waitingHuman, 4);
      expect(overview.newCustomers, 20);
      expect(overview.newLeads, 8);
      expect(overview.transactionsNeedingReview, 3);
      expect(overview.connections['whatsapp'], 12);
      expect(overview.connections['instagram'], 3);

      final exported = overview.toJson();
      expect(exported['open_conversations'], 15);
      expect(exported['connections'], {'whatsapp': 12, 'instagram': 3});
    });

    test('BusinessPolicy fromJson and toJson serialization', () {
      final json = {
        'business_id': 'biz_1',
        'ai_mode': 'suggest',
        'default_human_review': true,
        'allow_auto_reply': false,
        'allow_auto_lead_creation': true,
        'allow_auto_transaction_draft': true,
        'allow_auto_confirmation': false,
        'resource_version': 'rv_100',
      };

      final policy = BusinessPolicy.fromJson(json);
      expect(policy.businessId, 'biz_1');
      expect(policy.aiMode, 'suggest');
      expect(policy.defaultHumanReview, true);
      expect(policy.allowAutoReply, false);
      expect(policy.allowAutoLeadCreation, true);
      expect(policy.allowAutoTransactionDraft, true);
      expect(policy.allowAutoConfirmation, false);
      expect(policy.resourceVersion, 'rv_100');

      final exported = policy.toJson();
      expect(exported['ai_mode'], 'suggest');
      expect(exported['resource_version'], 'rv_100');
    });

    test('Conversation and CustomerSummary serialization', () {
      final json = {
        'id': 'conv_001',
        'business_id': 'biz_1',
        'customer': {'id': 'cust_99', 'display_name': 'فاطمة علي'},
        'state': 'waiting_human',
        'ownership': 'assigned',
        'ai_mode': 'off',
        'priority': 'urgent',
        'last_activity_at': '2026-10-15T10:00:00Z',
        'resource_version': 'rv_50',
        'labels': ['vip', 'wholesale'],
        'assignment': {'principal_id': 'p_42'},
      };

      final conv = Conversation.fromJson(json);
      expect(conv.id, 'conv_001');
      expect(conv.customer.id, 'cust_99');
      expect(conv.customer.displayName, 'فاطمة علي');
      expect(conv.state, 'waiting_human');
      expect(conv.priority, 'urgent');
      expect(conv.labels, ['vip', 'wholesale']);
      expect(conv.assignment?['principal_id'], 'p_42');

      final exported = conv.toJson();
      expect(exported['state'], 'waiting_human');
      expect((exported['labels'] as List).length, 2);
    });

    test('Message and Private Note serialization', () {
      final json = {
        'id': 'msg_001',
        'conversation_id': 'conv_001',
        'direction': 'outbound',
        'origin': 'human_agent',
        'status': 'delivered',
        'text': 'ملاحظة خاصة: تم التنسيق مع المستودع',
        'private': true,
        'created_at': '2026-10-15T11:00:00Z',
      };

      final msg = Message.fromJson(json);
      expect(msg.id, 'msg_001');
      expect(msg.direction, 'outbound');
      expect(msg.origin, 'human_agent');
      expect(msg.private, true);
      expect(msg.text, contains('ملاحظة خاصة'));

      final exported = msg.toJson();
      expect(exported['private'], true);
    });

    test('CannedReply serialization', () {
      final json = {
        'id': 'cr_001',
        'business_id': 'biz_1',
        'title': 'الترحيب العام',
        'shortcut': '!welcome',
        'body': 'أهلاً بك في متجرنا، نسعد بخدمتك!',
        'status': 'active',
        'resource_version': 'rv_10',
      };

      final reply = CannedReply.fromJson(json);
      expect(reply.id, 'cr_001');
      expect(reply.title, 'الترحيب العام');
      expect(reply.shortcut, '!welcome');
      expect(reply.body, contains('أهلاً بك'));
      expect(reply.status, 'active');
    });
  });

  group('Phase 2 Merchant Repository API Integration Tests', () {
    test(
      'getDashboardOverview calls GET /businesses/{id}/dashboard/overview',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.path,
            '/api/v1/businesses/biz_123/dashboard/overview',
          );
          expect(request.headers['Authorization'], 'Bearer valid_token');

          final body = {
            'data': {
              'open_conversations': 10,
              'waiting_human': 3,
              'new_customers': 14,
              'new_leads': 5,
              'transactions_needing_review': 1,
              'connections': {'whatsapp': 8, 'instagram': 2},
            },
            'meta': {'request_id': 'req_dash_01'},
          };
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: client);
        apiClient.setAccessToken('valid_token');
        final repo = MerchantRepository(apiClient: apiClient);

        final overview = await repo.getDashboardOverview('biz_123');
        expect(overview.openConversations, 10);
        expect(overview.waitingHuman, 3);
        expect(overview.connections['whatsapp'], 8);
      },
    );

    test(
      'getBusinessPolicy and updateBusinessPolicy send If-Match header',
      () async {
        int step = 0;
        final client = MockClient((request) async {
          if (step == 0) {
            step++;
            expect(request.method, 'GET');
            expect(request.url.path, '/api/v1/businesses/biz_123/policy');
            final body = {
              'data': {
                'business_id': 'biz_123',
                'ai_mode': 'suggest',
                'default_human_review': false,
                'allow_auto_reply': false,
                'allow_auto_lead_creation': false,
                'allow_auto_transaction_draft': false,
                'allow_auto_confirmation': false,
                'resource_version': 'v1',
              },
              'meta': {'request_id': 'req_pol_01'},
            };
            return http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else {
            expect(request.method, 'PATCH');
            expect(request.url.path, '/api/v1/businesses/biz_123/policy');
            expect(request.headers['If-Match'], 'v1');

            final reqBody = jsonDecode(request.body) as Map<String, dynamic>;
            expect(reqBody['ai_mode'], 'auto');
            expect(reqBody['allow_auto_reply'], true);

            final body = {
              'data': {
                'business_id': 'biz_123',
                'ai_mode': 'auto',
                'default_human_review': false,
                'allow_auto_reply': true,
                'allow_auto_lead_creation': false,
                'allow_auto_transaction_draft': false,
                'allow_auto_confirmation': false,
                'resource_version': 'v2',
              },
              'meta': {'request_id': 'req_pol_02'},
            };
            return http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        });

        final apiClient = ApiClient(client: client);
        apiClient.setAccessToken('valid_token');
        final repo = MerchantRepository(apiClient: apiClient);

        final policy = await repo.getBusinessPolicy('biz_123');
        expect(policy.aiMode, 'suggest');

        final updated = await repo.updateBusinessPolicy(
          businessId: 'biz_123',
          aiMode: 'auto',
          allowAutoReply: true,
          ifMatch: policy.resourceVersion,
        );
        expect(updated.aiMode, 'auto');
        expect(updated.allowAutoReply, true);
        expect(updated.resourceVersion, 'v2');
      },
    );

    test('listConversations with query parameters', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/businesses/biz_123/conversations');
        expect(request.url.queryParameters['state'], 'waiting_human');
        expect(request.url.queryParameters['limit'], '10');

        final body = {
          'data': [
            {
              'id': 'conv_1',
              'business_id': 'biz_123',
              'customer': {'id': 'cust_1', 'display_name': 'عميل تجريبي'},
              'state': 'waiting_human',
              'ownership': 'unassigned',
              'ai_mode': 'off',
              'priority': 'high',
              'last_activity_at': '2026-10-15T12:00:00Z',
              'resource_version': 'v1',
              'labels': ['vip'],
            },
          ],
          'meta': {'request_id': 'req_conv_01'},
        };
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: client);
      apiClient.setAccessToken('valid_token');
      final repo = MerchantRepository(apiClient: apiClient);

      final list = await repo.listConversations(
        businessId: 'biz_123',
        state: 'waiting_human',
        limit: 10,
      );

      expect(list.length, 1);
      expect(list[0].id, 'conv_1');
      expect(list[0].priority, 'high');
      expect(list[0].customer.displayName, 'عميل تجريبي');
    });

    test('sendMessage, addPrivateNote, and sendCannedReply', () async {
      int callIndex = 0;
      final client = MockClient((request) async {
        if (callIndex == 0) {
          // Public message
          callIndex++;
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/businesses/biz_123/conversations/conv_1/messages',
          );
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          final parsed = jsonDecode(request.body) as Map<String, dynamic>;
          expect(parsed['text'], 'مرحباً بك عميلنا العزيز');

          final body = {
            'data': {
              'id': 'msg_1',
              'conversation_id': 'conv_1',
              'direction': 'outbound',
              'origin': 'human_agent',
              'status': 'delivered',
              'text': 'مرحباً بك عميلنا العزيز',
              'private': false,
            },
            'meta': {'request_id': 'req_msg_01'},
          };
          return http.Response(
            jsonEncode(body),
            201,
            headers: {'content-type': 'application/json'},
          );
        } else if (callIndex == 1) {
          // Private note
          callIndex++;
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/businesses/biz_123/conversations/conv_1/notes',
          );
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          final parsed = jsonDecode(request.body) as Map<String, dynamic>;
          expect(parsed['text'], 'ملاحظة خاصة: العميل يطلب تخفيض');

          final body = {
            'data': {
              'id': 'msg_2',
              'conversation_id': 'conv_1',
              'direction': 'outbound',
              'origin': 'human_agent',
              'status': 'accepted',
              'text': 'ملاحظة خاصة: العميل يطلب تخفيض',
              'private': true,
            },
            'meta': {'request_id': 'req_msg_02'},
          };
          return http.Response(
            jsonEncode(body),
            201,
            headers: {'content-type': 'application/json'},
          );
        } else {
          // Send canned reply
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/businesses/biz_123/conversations/conv_1/canned-replies/cr_99/send',
          );
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);

          final body = {
            'data': {
              'id': 'msg_3',
              'conversation_id': 'conv_1',
              'direction': 'outbound',
              'origin': 'human_agent',
              'status': 'delivered',
              'text': 'تم إرسال الرد الجاهز',
              'private': false,
            },
            'meta': {'request_id': 'req_msg_03'},
          };
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final apiClient = ApiClient(client: client);
      apiClient.setAccessToken('valid_token');
      final repo = MerchantRepository(apiClient: apiClient);

      final msg = await repo.sendMessage(
        businessId: 'biz_123',
        conversationId: 'conv_1',
        text: 'مرحباً بك عميلنا العزيز',
      );
      expect(msg.id, 'msg_1');
      expect(msg.private, false);

      final note = await repo.addPrivateNote(
        businessId: 'biz_123',
        conversationId: 'conv_1',
        text: 'ملاحظة خاصة: العميل يطلب تخفيض',
      );
      expect(note.id, 'msg_2');
      expect(note.private, true);

      final cannedMsg = await repo.sendCannedReply(
        businessId: 'biz_123',
        conversationId: 'conv_1',
        cannedReplyId: 'cr_99',
      );
      expect(cannedMsg.id, 'msg_3');
    });

    test('assignConversation and updateConversationLabels', () async {
      int callIdx = 0;
      final client = MockClient((request) async {
        if (callIdx == 0) {
          callIdx++;
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/businesses/biz_123/conversations/conv_1/assign',
          );
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          final parsed = jsonDecode(request.body) as Map<String, dynamic>;
          expect(parsed['assignee_principal_id'], 'p_new');

          final body = {
            'data': {
              'id': 'conv_1',
              'business_id': 'biz_123',
              'customer': {'id': 'c_1'},
              'state': 'open',
              'ownership': 'assigned',
              'ai_mode': 'off',
              'priority': 'normal',
              'last_activity_at': '2026-10-15T12:00:00Z',
              'resource_version': 'v2',
              'labels': [],
              'assignment': {'principal_id': 'p_new'},
            },
            'meta': {'request_id': 'req_assign_01'},
          };
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/businesses/biz_123/conversations/conv_1/labels',
          );
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          final parsed = jsonDecode(request.body) as Map<String, dynamic>;
          expect(parsed['add'], ['urgent']);

          final body = {
            'data': {
              'id': 'conv_1',
              'business_id': 'biz_123',
              'customer': {'id': 'c_1'},
              'state': 'open',
              'ownership': 'assigned',
              'ai_mode': 'off',
              'priority': 'normal',
              'last_activity_at': '2026-10-15T12:00:00Z',
              'resource_version': 'v3',
              'labels': ['urgent'],
              'assignment': {'principal_id': 'p_new'},
            },
            'meta': {'request_id': 'req_label_01'},
          };
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final apiClient = ApiClient(client: client);
      apiClient.setAccessToken('valid_token');
      final repo = MerchantRepository(apiClient: apiClient);

      final assigned = await repo.assignConversation(
        businessId: 'biz_123',
        conversationId: 'conv_1',
        assigneePrincipalId: 'p_new',
      );
      expect(assigned.assignment?['principal_id'], 'p_new');

      final labeled = await repo.updateConversationLabels(
        businessId: 'biz_123',
        conversationId: 'conv_1',
        add: ['urgent'],
      );
      expect(labeled.labels, ['urgent']);
    });
  });

  group('MerchantProvider State Management Tests', () {
    test(
      'loadDashboardOverview updates state and catches ApiErrorEnvelope',
      () async {
        final client = MockClient((request) async {
          final body = {
            'error': {
              'code': 'FORBIDDEN',
              'message': 'ليس لديك صلاحية الوصول إلى لوحة المعلومات',
            },
            'meta': {'request_id': 'req_err_99'},
          };
          return http.Response(
            jsonEncode(body),
            403,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: client);
        final repo = MerchantRepository(apiClient: apiClient);
        final provider = MerchantProvider(merchantRepository: repo);

        await provider.loadDashboardOverview('biz_forbidden');
        expect(provider.dashboardOverview, isNull);
        expect(
          provider.dashboardError,
          'ليس لديك صلاحية الوصول إلى لوحة المعلومات',
        );
        expect(provider.lastRequestId, 'req_err_99');
      },
    );
  });
}
