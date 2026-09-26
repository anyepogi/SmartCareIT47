import 'personal_information.dart';

class DoctorModel {
	final int? doctorId;
	final int userId;
	final int? personalInformationId;
	final PersonalInformation? personalInformation;

	DoctorModel({
		this.doctorId,
		required this.userId,
		this.personalInformationId,
		this.personalInformation,
	});

	factory DoctorModel.fromJson(Map<String, dynamic> json) {
		return DoctorModel(
			doctorId: json['doctor_id'],
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
			'doctor_id': doctorId,
			'user_id': userId,
			'personal_information_id': personalInformationId,
			'personal_information': personalInformation?.toJson(),
		};
	}
}

