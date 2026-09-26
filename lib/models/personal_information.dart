class PersonalInformation {
	final int? personalInformationId;
	final String firstName;
	final String? middleName;
	final String lastName;
	final DateTime? dateOfBirth;
	final String? contactNumber;
	final String? gender;
	final String? occupation;
	final String? civilStatus;
	final String? address;

	PersonalInformation({
		this.personalInformationId,
		required this.firstName,
		this.middleName,
		required this.lastName,
		this.dateOfBirth,
		this.contactNumber,
		this.gender,
		this.occupation,
		this.civilStatus,
		this.address,
	});

	factory PersonalInformation.fromJson(Map<String, dynamic> json) {
		return PersonalInformation(
			personalInformationId: json['personal_information_id'],
			firstName: json['first_name'] ?? '',
			middleName: json['middle_name'],
			lastName: json['last_name'] ?? '',
			dateOfBirth: json['date_of_birth'] != null
					? DateTime.tryParse(json['date_of_birth'])
					: null,
			contactNumber: json['contact_number'],
			gender: json['gender'],
			occupation: json['occupation'],
			civilStatus: json['civil_status'],
			address: json['address'],
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'personal_information_id': personalInformationId,
			'first_name': firstName,
			'middle_name': middleName,
			'last_name': lastName,
			'date_of_birth': dateOfBirth?.toIso8601String(),
			'contact_number': contactNumber,
			'gender': gender,
			'occupation': occupation,
			'civil_status': civilStatus,
			'address': address,
		};
	}
}

