import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/app_header.dart';

/// Privacy Policy.
///
/// Content mirrors kinship-studio's `app/(public)/privacy/page.tsx`. The web
/// page's nav and footer are omitted — this opens from the signup form, where
/// the only useful exit is back.
///
/// The two copies will drift. Legal text changes rarely and has to be exact,
/// so it is transcribed rather than fetched; if the web version is amended,
/// this file needs the same edit.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const lastModified = 'Last modified May 5, 2025.';
  static const supportEmail = 'support@kinship.systems';

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Scaffold(
      backgroundColor: colors.deep,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: colors.sky,
                        ),
                        child: const Text('← Back'),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'LEGAL',
                        style: text.eyebrowSmall.copyWith(color: colors.quiet),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Privacy Policy',
                        style: text.h2.copyWith(color: colors.gold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lastModified,
                        style: text.body.copyWith(
                          color: colors.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      const _Body(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _P('This privacy policy ("Privacy Policy") explains how Kiduna Club '
            '("KC," "our," "we," or "us") collects, uses, and discloses '
            'information about you. This Privacy Policy applies when you visit '
            'this website (the "Website"), use our mobile app, interact with '
            'any of our AI agents, contact our team by email or Telegram, '
            'engage with us on social media, or otherwise interact with us.'),
        _P('We may change this Privacy Policy from time to time. If we make '
            'changes, we will notify you by revising the date at the top of '
            'this policy and, in some cases, we may provide you with '
            'additional notice (such as adding a statement to our Website or '
            'sending you a notification). We encourage you to review this '
            'Privacy Policy regularly to stay informed about our information '
            'practices and the choices available to you.'),

        _H2('Collection of Information'),
        _H3('Information You Provide to Us'),
        _P('We collect information you provide directly to us. For example, '
            'you share information directly with us when you fill out a form, '
            'make a purchase, mint a token, connect with us on third-party '
            'platforms, participate in a contest or promotion, request '
            'customer support, or otherwise communicate with us. The types of '
            'personal information we may collect include your name, email '
            'address, biographical data, postal address, wallet address, phone '
            'number, credit card and other payment information, and any other '
            'information you choose to provide.'),

        _H3('Information We Collect Automatically When You Interact with Us'),
        _P('When you access or use our Website or otherwise transact business '
            'with us, we automatically collect certain information, including:'),
        _Bullet(
          bold: 'Transactional Information:',
          body: ' When you make a purchase or return, we collect information '
              'about the transaction, such as product details, purchase price, '
              'and the date and location of the transaction.',
        ),
        _Bullet(
          bold: 'Device and Usage Information:',
          body: ' We collect information about how you access our Website, '
              'including data about the device and network you use, such as '
              'your hardware model, operating system version, mobile network, '
              'IP address, unique device identifiers, browser type, and app '
              'version. We also collect information about your activity on our '
              'Website, such as access times, pages viewed, links clicked, and '
              'the page you visited before navigating to our Website.',
        ),
        _Bullet(
          bold: 'Location Information:',
          body: ' In accordance with your device permissions, we may collect '
              'information about the precise location of your device. You may '
              'stop the collection of precise location information at any time.',
        ),
        _Bullet(
          bold: 'Information Collected by Cookies and Similar Tracking '
              'Technologies:',
          body: ' We (and our service providers) use tracking technologies, '
              'such as cookies and web beacons, to collect information about '
              'you. Cookies are small data files stored on your hard drive or '
              'in device memory that help us improve our Website and your '
              'experience, see which areas and features of our Website are '
              'popular, and count visits. Web beacons (also known as "pixel '
              'tags" or "clear GIFs") are electronic images that we use on our '
              'Website and in our emails to help deliver cookies, count '
              'visits, and understand usage and campaign effectiveness.',
        ),

        _H3('Information We Collect from Other Sources'),
        _P('We obtain information from third-party sources. For example, we '
            'may collect information about you from identity verification '
            'services, data analytics providers, wallet address providers, and '
            'mailing list providers (if applicable).'),

        _H2('Use of Information'),
        _P('We use the information we collect to:'),
        _Bullet(body: 'Provide, maintain, and improve our products and services;'),
        _Bullet(
          body: 'Process transactions and send you related information, '
              'including confirmations, receipts, invoices, customer '
              'experience surveys, and recall notices;',
        ),
        _Bullet(body: 'Personalize and improve your experience on our Website;'),
        _Bullet(
          body: 'Send you technical notices, security alerts, and support and '
              'administrative messages;',
        ),
        _Bullet(
          body: 'Respond to your comments and questions and provide customer '
              'service;',
        ),
        _Bullet(
          body: 'Communicate with you about products, services, and events '
              'offered by us and others and provide news and information that '
              'we think will interest you;',
        ),
        _Bullet(
          body: 'Monitor and analyze trends, usage, and activities in '
              'connection with our Website;',
        ),
        _Bullet(
          body: 'Facilitate contests, sweepstakes, and promotions and process '
              'and deliver entries and rewards;',
        ),
        _Bullet(
          body: 'Detect, investigate, and prevent security incidents and other '
              'malicious, deceptive, fraudulent, or illegal activity and '
              'protect the rights and property of KC and others;',
        ),
        _Bullet(body: 'Debug to identify and repair errors in our Website;'),
        _Bullet(body: 'Comply with our legal and financial obligations; and'),
        _Bullet(
          body: 'Carry out any other purpose described to you at the time the '
              'information was collected.',
        ),

        _H2('Sharing of Information'),
        _P('We share personal information in the following circumstances or as '
            'otherwise described in this policy:'),
        _Bullet(
          body: 'We share personal information with vendors, service '
              'providers, and consultants that need access to personal '
              'information in order to perform services for us, such as '
              'companies that assist us with web hosting, shipping and '
              'delivery, payment processing, fraud prevention, customer '
              'service, and marketing and advertising.',
        ),
        _Bullet(
          body: 'We may disclose personal information if we believe that '
              'disclosure is in accordance with, or required by, any '
              'applicable law or legal process, including lawful requests by '
              'public authorities to meet national security or law enforcement '
              'requirements.',
        ),
        _Bullet(
          body: 'We may share personal information if we believe that your '
              'actions are inconsistent with our user agreements or policies, '
              'if we believe that you have violated the law, or if we believe '
              'it is necessary to protect the rights, property, and safety of '
              'KC, our users, the public, or others.',
        ),
        _Bullet(
          body: 'We share personal information with our lawyers and other '
              'professional advisors where necessary to obtain advice or '
              'otherwise protect and manage our business interests.',
        ),
        _Bullet(
          body: 'We may share personal information in connection with, or '
              'during negotiations concerning, any merger, sale of company '
              'assets, financing, or acquisition of all or a portion of our '
              'business by another company.',
        ),
        _Bullet(
          body: 'We share personal information with your consent or at your '
              'direction.',
        ),
        _Bullet(
          body: 'We also share aggregated or de-identified information that '
              'cannot reasonably be used to identify you.',
        ),

        _H2('Analytics'),
        _P('We may collect your IP address, web browser, mobile network '
            'information, pages viewed, time spent on pages or in mobile apps, '
            'links clicked, and conversion information. This information may '
            'be used by KC and others to, among other things, research, '
            'analyze and track data, determine the popularity of certain '
            'content, and better understand your online activity. However, if '
            'you have deleted and disabled cookies, these uses will not be '
            'possible to the extent they are based on cookie information. We '
            'use Google Analytics to analyze traffic.'),
        _LinkP(
          before: 'You can find out more information about Google Analytics '
              'cookies at ',
          linkText: 'developers.google.com',
          url: 'https://developers.google.com/analytics/devguides/collection/analyticsjs/cookie-usage',
          after: '. To opt out of Google Analytics relating to your use of our '
              'site, you can download and install the browser plugin available '
              'at ',
          linkText2: 'tools.google.com/dlpage/gaoptout',
          url2: 'https://tools.google.com/dlpage/gaoptout?hl=en',
          after2: '.',
        ),

        _H2('Transfer of Information to the United States and Other Countries'),
        _P('We operate and engage service providers in various jurisdictions. '
            'Therefore, we and our service providers may transfer your '
            'personal information to, or store or access it in, jurisdictions '
            'that may not provide levels of data protection that are '
            'equivalent to those of your home jurisdiction. By using our site, '
            'you acknowledge and agree to such transfers and processing, '
            'including to and in the United States. We will take steps to '
            'ensure that your personal information receives an adequate level '
            'of protection in the jurisdictions in which we process it.'),

        _H2('Your Choices'),
        _H3('Cookies'),
        _P('Most browsers are set to accept cookies by default. If you prefer, '
            'you can usually set your browser to disable cookies, or to alert '
            'you when cookies are being sent. Likewise, most mobile devices '
            'allow you to disable the ability for geolocation information to '
            'be collected from your mobile device. The help function on most '
            'browsers and mobile devices contains instructions on how to set '
            'your browser to notify you before accepting cookies, disable '
            'cookies entirely, or disable the collection of geolocation data. '
            'You need to set each browser, on each device you use to surf the '
            'Web. Thus, if you use multiple browsers (e.g., Chrome, Safari, '
            'Firefox, etc.), you should repeat this procedure with each one. '
            'Similarly, if you connect to the Web from multiple devices (e.g., '
            'work and home), you need to set each browser on each device. '
            'Depending on your jurisdiction, you may be able to utilize '
            'additional cookie management tools. Please note that removing or '
            'rejecting cookies could affect the availability and functionality '
            'of our Website.'),
        _H3('Communications Preferences'),
        _P('You may opt out of receiving newsletters from us by following the '
            'instructions in those communications.'),

        _H2('Your California Privacy Rights'),
        _P('The California Consumer Privacy Act or "CCPA" (Cal. Civ. Code '
            '§ 1798.100 et seq.) affords consumers residing in California '
            'certain rights with respect to their personal information. If you '
            'are a California resident, this section applies to you.'),
        _H3('California Consumer Privacy Act'),
        _P('In the preceding 12 months, we have collected the following '
            'categories of personal information: identifiers, financial '
            'information, biometric information, internet or electric network '
            'activity information, and geolocation data. For details about the '
            'precise data points we collect and the categories of sources of '
            'such collection, please see the Collection of Information section '
            'above. We collect personal information for the business and '
            'commercial purposes described in the Use of Information section '
            'above.'),
        _P('We do not and will not sell your personal information.', bold: true),
        _P('Subject to certain limitations, you have the right to (1) request '
            'to know more about the categories and specific pieces of personal '
            'information we collect, use, and disclose, (2) request deletion of '
            'your personal information, and (3) not be discriminated against '
            'for exercising these rights. You may make these requests by '
            'contacting us by email at $_email. We will verify your request by '
            'asking you to provide information related to your recent '
            'interactions with us. We will not discriminate against you if you '
            'exercise your rights under the CCPA.'),

        _H2('Additional Disclosures for Individuals in Europe'),
        _P('If you are located in the European Economic Area ("EEA"), the '
            'United Kingdom, or Switzerland, you have certain rights and '
            'protections under the law regarding the processing of your '
            'personal data, and this section applies to you.'),
        _H3('Legal Basis for Processing'),
        _P('When we process your personal data, we will do so in reliance on '
            'the following lawful bases:'),
        _Bullet(
          body: 'To perform our responsibilities under our contract with you '
              '(e.g., processing payments for and providing the products and '
              'services you requested).',
        ),
        _Bullet(
          body: 'When we have a legitimate interest in processing your '
              'personal data to operate our business or protect our interests '
              '(e.g., to provide, maintain, and improve our products and '
              'services, conduct data analytics, and communicate with you).',
        ),
        _Bullet(
          body: 'To comply with our legal obligations (e.g., to maintain a '
              'record of your consents and track those who have opted out of '
              'communications).',
        ),
        _Bullet(
          body: 'When we have your consent to do so (e.g., when you opt in to '
              'receive communications from us). When consent is the legal '
              'basis for our processing of your personal data, you may '
              'withdraw such consent at any time.',
        ),
        _H3('Data Retention'),
        _P('We store personal data for as long as necessary to carry out the '
            'purposes for which we originally collected it and for other '
            'legitimate business purposes, including to meet our legal, '
            'regulatory, or other compliance obligations.'),
        _H3('Data Subject Requests'),
        _P('Subject to certain limitations, you have the right to request '
            'access to the personal data we hold about you and to receive your '
            'data in a portable format, the right to ask that your personal '
            'data be corrected or erased, and the right to object to, or '
            'request that we restrict, certain processing. If you would like '
            'to exercise any of these rights, please contact our technology '
            'services provider at $_email.'),
        _H3('Questions or Complaints'),
        _P('If you have a concern about our processing of personal data that '
            'we are not able to resolve, you have the right to lodge a '
            'complaint with the Data Protection Authority where you reside. '
            'Contact details for your Data Protection Authority can be found '
            'using the links below:'),
        _LinkBullet(
          before: 'For individuals in the EEA: ',
          linkText: 'edpb.europa.eu',
          url: 'https://edpb.europa.eu/about-edpb/board/members_en',
        ),
        _LinkBullet(
          before: 'For individuals in the UK: ',
          linkText: 'ico.org.uk',
          url: 'https://ico.org.uk/global/contact-us/',
        ),
        _LinkBullet(
          before: 'For individuals in Switzerland: ',
          linkText: 'edoeb.admin.ch',
          url: 'https://www.edoeb.admin.ch/edoeb/en/home/the-fdpic/contact.html',
        ),

        _H2('Contact Us'),
        _P('If you have any questions about this Privacy Policy, please '
            'contact us at $_email.'),
      ],
    );
  }
}

const _email = 'support@kinship.systems';

// ═══════════════════════════════════════════════════════════════════════
// Text primitives
// ═══════════════════════════════════════════════════════════════════════

class _H2 extends StatelessWidget {
  const _H2(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Text(
        text,
        style: context.kidunaText.h4.copyWith(color: colors.gold),
      ),
    );
  }
}

class _H3 extends StatelessWidget {
  const _H3(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: context.kidunaText.body.copyWith(
          color: colors.cream,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _P extends StatelessWidget {
  const _P(this.text, {this.bold = false});
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: context.kidunaText.body.copyWith(
          color: bold ? colors.cream : colors.muted,
          fontSize: 15,
          height: 1.65,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({this.bold, required this.body});
  final String? bold;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final base = text.body.copyWith(
      color: colors.muted,
      fontSize: 15,
      height: 1.65,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('•  ', style: base),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: base,
                children: [
                  if (bold != null)
                    TextSpan(
                      text: bold,
                      style: base.copyWith(
                        color: colors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paragraph containing up to two external links.
class _LinkP extends StatelessWidget {
  const _LinkP({
    required this.before,
    required this.linkText,
    required this.url,
    required this.after,
    this.linkText2,
    this.url2,
    this.after2,
  });

  final String before;
  final String linkText;
  final String url;
  final String after;
  final String? linkText2;
  final String? url2;
  final String? after2;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final base = context.kidunaText.body.copyWith(
      color: colors.muted,
      fontSize: 15,
      height: 1.65,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: base,
          children: [
            TextSpan(text: before),
            _link(linkText, url, colors.sky, base),
            TextSpan(text: after),
            if (linkText2 != null && url2 != null)
              _link(linkText2!, url2!, colors.sky, base),
            if (after2 != null) TextSpan(text: after2),
          ],
        ),
      ),
    );
  }
}

class _LinkBullet extends StatelessWidget {
  const _LinkBullet({
    required this.before,
    required this.linkText,
    required this.url,
  });

  final String before;
  final String linkText;
  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final base = context.kidunaText.body.copyWith(
      color: colors.muted,
      fontSize: 15,
      height: 1.65,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('•  ', style: base),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: base,
                children: [
                  TextSpan(text: before),
                  _link(linkText, url, colors.sky, base),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable external link span. Shared so link styling stays consistent.
TextSpan _link(String label, String url, Color linkColor, TextStyle base) {
  return TextSpan(
    text: label,
    style: base.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () => launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          ),
  );
}
