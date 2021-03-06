require "spec_helper"

describe CampusData do

  before do
    @current_terms = Settings.sakai_proxy.current_terms_codes
  end

  it "should find Oliver" do
    data = CampusData.get_person_attributes(2040)
    data['first_name'].should == "Oliver"
    if CampusData.test_data?
      data[:roles][:student].should == false
      data[:roles][:faculty].should == false
      data[:roles][:staff].should == true
    end
  end

  it "should find a user who has a bunch of blocks" do
    data = CampusData.get_person_attributes(300847)
    if CampusData.test_data?
      # we will only have predictable reg_status_cd values in our fake Oracle db.
      data['educ_level'].should == "Masters"
      data['admin_blk_flag'].should == "Y"
      data['acad_blk_flag'].should == "Y"
      data['fin_blk_flag'].should == "Y"
      data['reg_blk_flag'].should == "Y"
      data['tot_enroll_unit'].should == "1"
      data['cal_residency_flag'].should == "N"
      data[:roles][:student].should == true
      data[:roles][:faculty].should == false
      data[:roles][:staff].should == true
    end
  end

  it "should find Stu TestB's registration status" do
    data = CampusData.get_reg_status(300846)
    if CampusData.test_data?
      data['ldap_uid'].should == "300846"
      # we will only have predictable reg_status_cd values in our fake Oracle db.
      data['reg_status_cd'].should == "C"
    end
  end

  it "should return nil from get_reg_status if an existing user has no reg status" do
    data = CampusData.get_reg_status("2040")
    data.should be_nil
  end

  it "should return nil from get_reg_status if the user does not exist" do
    data = CampusData.get_reg_status("0")
    data.should be_nil
  end

  it "should find some students in Biology 1a" do
    students = CampusData.get_enrolled_students("7309", "2013", "D")
    students.should_not be_nil
    if CampusData.test_data?
      # we will only have predictable enrollments in our fake Oracle db.
      students.empty?.should be_false
    end
    students.each do |student_row|
      student_row["enroll_status"].blank?.should be_false
      student_row["student_id"].blank?.should be_false
    end
  end

  it "should find a course" do
    course = CampusData.get_course_from_section("7366", "2013", "B")
    course.should_not be_nil
    if CampusData.test_data?
      # we will only have predictable data in our fake Oracle db.
      course["course_title"].should == "General Biology Lecture"
      course["dept_name"].should == "BIOLOGY"
      course["catalog_id"].should == "1A"
    end
  end

  it "should find sections from CCNs" do
    courses = CampusData.get_sections_from_ccns("2013", "D", ["7309", "7366", "919191", "16171"])
    pp courses
    courses.should_not be_nil
    if CampusData.test_data?
      courses.length.should == 3
      courses.index{|c|
        c['dept_name'] == "BIOLOGY" &&
        c['catalog_id'] == "1A" &&
        c['course_title'] == "General Biology Lecture" &&
        c['primary_secondary_cd'] == 'P' &&
        c['instruction_format'] == 'LEC' &&
        c['section_num'] == '003'
      }.should_not be_nil
    end
  end

  it "should find sections from course" do
    sections = CampusData.get_sections_from_course('BIOLOGY', '1A', 2013, 'D')
    sections.empty?.should be_false
    if CampusData.test_data?
      # Should not include canceled section
      sections.length.should == 3
      # Should include at least one lecture section
      sections.index{|s| s['instruction_format'] == 'LEC'}.should_not be_nil
    end
  end

  it "should find where a person is enrolled, with grades where available" do
    sections = CampusData.get_enrolled_sections('300939')
    sections.should_not be_nil
    transcripts = CampusData.get_transcript_grades('300939')
    transcripts.should_not be_nil
    if CampusData.test_data?
      sections.length.should == 7
      transcripts.length.should == 2
      expected_grades = {5 => 'B', 6 => 'C+'}
      expected_grades.keys.each do |idx|
        section = sections[idx]
        transcript = transcripts.select {|t|
          t['term_yr'] == section['term_yr'] &&
              t['term_cd'] == section['term_cd'] &&
              t['dept_name'] == section['dept_name'] &&
              t['catalog_id'] == section['catalog_id']
        }[0]
        transcript.should_not be_nil
        transcript['grade'].should == expected_grades[idx]
      end
    end
  end

  it "should be able to limit enrollment queries" do
    sections = CampusData.get_enrolled_sections('300939', @current_terms)
    sections.should_not be_nil
    sections.length.should == 3 if CampusData.test_data?
  end

  context "#get_enrolled_sections", if: SakaiData.test_data? do
    subject { CampusData.get_enrolled_sections('300939') }

    it { should_not be_blank }
    it { subject.all? { |section| section.has_key?("cred_cd") } }
  end

  it "should find where a person is teaching" do
    sections = CampusData.get_instructing_sections('238382')
    sections.should_not be_nil
    sections.length.should == 5 if CampusData.test_data?
  end

  it "should be able to limit teaching assignment queries" do
    sections = CampusData.get_instructing_sections('238382', @current_terms)
    sections.should_not be_nil
    sections.length.should == 3 if CampusData.test_data?
  end

  it "should check whether the db is alive" do
    alive = CampusData.database_alive?
    alive.should be_true
  end

  it "should report DB outage" do
    CampusData.connection.stub(:select_one).and_raise(
        ActiveRecord::StatementInvalid,
        "Java::JavaSql::SQLRecoverableException: IO Error: The Network Adapter could not establish the connection: select 1 from DUAL"
    )
    is_ok = CampusData.database_alive?
    is_ok.should be_false
  end

  it "should handle a person with no affiliations" do
    # Temp Agency Staff has no affiliations
    data = CampusData.get_person_attributes(321765)
    data[:roles].each do |role_name, role_value|
      role_value.should be_false
    end
  end

  it "should return class schedule data" do
    data = CampusData.get_section_schedules("2013", "D", "16171")
    data.should_not be_nil
    if CampusData.test_data?
      data[0]["building_name"].should == "WHEELER"
      data[1]["building_name"].should == "DWINELLE"
    end
  end

  it "should return instructor data given a course control number" do
    data = CampusData.get_section_instructors("2013", "D", "7309")
    data.should_not be_nil
    if CampusData.test_data?
      data.length.should == 2
      data[0]["person_name"].present?.should be_true
      data[0]["instructor_func"].should == "1"
      data[1]["person_name"].should == "Chris Tweney"
      data[1]["instructor_func"].should == "4"
    end
  end

  it "should be able to get a whole lot of user records" do
    known_uids = ['238382', '2040', '3060', '211159', '322279']
    lotsa_uids = Array.new(1000 - known_uids.length) {|i| i + 1 }
    lotsa_uids.concat(known_uids)
    user_data = CampusData.get_basic_people_attributes(lotsa_uids)
    user_data.each do |row|
      known_uids.delete(row['ldap_uid'])
    end
    known_uids.empty?.should be_true
  end

  it "should be able to look up Tammi's student info" do
    info = CampusData.get_student_info "300939"
    info.should_not be_nil
    if CampusData.test_data?
      info["first_reg_term_cd"].should == "D"
      info["first_reg_term_yr"].should == "2013"
    end
  end

  it "should use affiliations to decide whether the user is a student" do
    CampusData.is_student?(
        {
            'student_id' => 1,
            'affiliations' => 'AFFILIATE-TYPE-GENERAL,EMPLOYEE-STATUS-EXPIRED,STUDENT-STATUS-EXPIRED'
        }
    ).should be_false
    CampusData.is_student?(
        {
            'student_id' => 2,
            'affiliations' => 'STUDENT-TYPE-REGISTERED,EMPLOYEE-TYPE-STAFF'
        }
    ).should be_true
    CampusData.is_student?(
        {
            'affiliations' => 'STUDENT-TYPE-REGISTERED,EMPLOYEE-TYPE-STAFF'
        }
    ).should be_false
    CampusData.is_student?(
        {
            'student_id' => 3,
            'affiliations' => 'EMPLOYEE-TYPE-STAFF,STUDENT-TYPE-NOT REGISTERED'
        }
    ).should be_true
  end

  it "should find a grad student that used to be an undergrad", if: CampusData.test_data? do
    CampusData.is_previous_ugrad?("212388").should be_true
    CampusData.is_previous_ugrad?("212389").should be_true #grad student expired, previous ugrad
    CampusData.is_previous_ugrad?("212390").should be_false #grad student, but not previous ugrad
    CampusData.is_previous_ugrad?("300939").should be_true #ugrad only
  end

  it "should say an instructor has instructional history", if: CampusData.test_data? do
    CampusData.has_instructor_history?("238382", Settings.sakai_proxy.academic_terms.instructor).should be_true
  end

  it "should say a student has student history", if: CampusData.test_data? do
    CampusData.has_student_history?("300939", Settings.sakai_proxy.academic_terms.student).should be_true
  end

  it "should say a staff member does not have instructional or student history", if: CampusData.test_data? do
    CampusData.has_instructor_history?("2040", Settings.sakai_proxy.academic_terms.instructor).should be_false
    CampusData.has_student_history?("2040", Settings.sakai_proxy.academic_terms.student).should be_false
  end

end
