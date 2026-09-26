import 'personal_information.dart';

class SecretaryModel {
	final int? secretaryId;
	final int userId;
	final int? personalInformationId;
	final PersonalInformation? personalInformation;

	SecretaryModel({
		this.secretaryId,
		required this.userId,
		this.personalInformationId,
		this.personalInformation,
	});

	factory SecretaryModel.fromJson(Map<String, dynamic> json) {
		return SecretaryModel(
			secretaryId: json['secretary_id'],
			userId: json['user_id'],
			personalInformationId: json['personal_information_id'],
			personalInformation: json['personal_information'] != null
					? PersonalInformation.fromJson(
							Map<String, dynamic>.from(json['personal_information']))
					: null,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'secretary_id': secretaryId,
			'user_id': userId,
			'personal_information_id': personalInformationId,
			'personal_information': personalInformation?.toJson(),
		};
	}
}

