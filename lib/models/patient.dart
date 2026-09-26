import 'personal_information.dart';

class PatientModel {
	final int? patientId;
	final int userId;
	final int? personalInformationId;
	final PersonalInformation? personalInformation;

	PatientModel({
		this.patientId,
		required this.userId,
		this.personalInformationId,
		this.personalInformation,
	});

	factory PatientModel.fromJson(Map<String, dynamic> json) {
		return PatientModel(
			patientId: json['patient_id'],
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
			'patient_id': patientId,
			'user_id': userId,
			'personal_information_id': personalInformationId,
			'personal_information':
					personalInformation?.toJson(),
		};
	}
}


