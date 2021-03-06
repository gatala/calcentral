class OecData < OracleDatabase
  include ActiveRecordHelper

  def self.get_all_students(course_cntl_nums=[])
    result = []
    use_pooled_connection {
      sql = <<-SQL
        select distinct person.first_name, person.last_name,
          person.email_address, person.ldap_uid
        from calcentral_person_info_vw person, calcentral_class_roster_vw r, calcentral_course_info_vw c
        where
          c.section_cancel_flag is null
          #{terms_query_clause('c', Settings.oec.current_terms_codes)}
          and c.course_cntl_num IN ( #{course_cntl_nums.join(',')} )
          and r.enroll_status != 'D'
          and r.term_yr = c.term_yr
          and r.term_cd = c.term_cd
          and r.course_cntl_num = c.course_cntl_num
          and r.student_ldap_uid = person.ldap_uid
        order by ldap_uid
      SQL
      result = connection.select_all(sql)
    }
    result
  end

  def self.get_all_instructors(course_cntl_nums=[])
    result = []
    use_pooled_connection {
      sql = <<-SQL
        select distinct person.first_name, person.last_name,
          person.email_address, person.ldap_uid, '23' AS blue_role
        from calcentral_person_info_vw person, calcentral_course_instr_vw bci, calcentral_course_info_vw c, calcentral_class_roster_vw r
        where
          c.section_cancel_flag is null
          #{terms_query_clause('c', Settings.oec.current_terms_codes)}
          and c.course_cntl_num IN ( #{course_cntl_nums.join(',')} )
          and r.enroll_status != 'D'
          and r.term_yr = c.term_yr
          and r.term_cd = c.term_cd
          and r.course_cntl_num = c.course_cntl_num
          and bci.term_yr = c.term_yr
          and bci.term_cd = c.term_cd
          and bci.course_cntl_num = c.course_cntl_num
          and person.ldap_uid = bci.instructor_ldap_uid
        order by ldap_uid
      SQL
      result = connection.select_all(sql)
    }
    result
  end

  def self.get_all_courses(course_cntl_nums = nil)
    result = []
    course_cntl_nums_clause = ''
    this_depts_clause = depts_clause
    if course_cntl_nums.present?
      course_cntl_nums_clause = " and c.course_cntl_num IN ( #{course_cntl_nums} )"
      this_depts_clause = ''
    end

    use_pooled_connection {
      sql = <<-SQL
      select
        c.term_yr || '-' || c.term_cd || '-' || c.course_cntl_num AS course_id,
        c.dept_name || ' ' || c.catalog_id || ' ' || c.instruction_format || ' ' || c.section_num || ' ' || c.course_title_short AS course_name,
        c.cross_listed_flag,
        (
          select listagg(course_cntl_num, ', ') within group (order by course_cntl_num)
          from calcentral_cross_listing_vw
          where term_yr = c.term_yr and term_cd = c.term_cd and crosslist_hash = x.crosslist_hash
        ) AS cross_listed_name,
        c.dept_name,
        c.catalog_id,
        c.instruction_format,
        c.section_num,
        c.primary_secondary_cd,
        c.course_title_short
      from calcentral_course_info_vw c
      left outer join calcentral_cross_listing_vw x ON ( x.term_yr = c.term_yr and x.term_cd = c.term_cd and x.course_cntl_num = c.course_cntl_num )
      where 1=1 #{terms_query_clause('c', Settings.oec.current_terms_codes)} #{this_depts_clause} #{course_cntl_nums_clause}
        and exists (
          select r.course_cntl_num
          from calcentral_class_roster_vw r
          where r.enroll_status != 'D'
            and r.term_yr = c.term_yr
            and r.term_cd = c.term_cd
            and r.course_cntl_num = c.course_cntl_num
            and rownum < 2
          )
      order by c.course_cntl_num
      SQL
      result = connection.select_all(sql)
    }
    result
  end

  def self.get_all_course_instructors(course_cntl_nums=[])
    result = []
    use_pooled_connection {
      sql = <<-SQL
      select distinct bci.term_yr || '-' || bci.term_cd || '-' || bci.course_cntl_num AS course_id,
        bci.instructor_ldap_uid AS ldap_uid, bci.instructor_func
      from calcentral_course_instr_vw bci, calcentral_course_info_vw c, calcentral_class_roster_vw r
      where
          c.section_cancel_flag is null
          #{terms_query_clause('c', Settings.oec.current_terms_codes)}
          and c.course_cntl_num IN ( #{course_cntl_nums.join(',')} )
          and r.enroll_status != 'D'
          and r.term_yr = c.term_yr
          and r.term_cd = c.term_cd
          and r.course_cntl_num = c.course_cntl_num
          and bci.term_yr = c.term_yr
          and bci.term_cd = c.term_cd
          and bci.course_cntl_num = c.course_cntl_num
      order by ldap_uid
      SQL
      result = connection.select_all(sql)
    }
    result
  end

  def self.get_all_course_students(course_cntl_nums=[])
    result = []
    use_pooled_connection {
      sql = <<-SQL
      select distinct r.term_yr || '-' || r.term_cd || '-' || r.course_cntl_num AS course_id,
        r.student_ldap_uid AS ldap_uid
      from calcentral_course_info_vw c, calcentral_class_roster_vw r
      where
          c.section_cancel_flag is null
          #{terms_query_clause('c', Settings.oec.current_terms_codes)}
          and c.course_cntl_num IN ( #{course_cntl_nums.join(',')} )
          and r.enroll_status != 'D'
          and r.term_yr = c.term_yr
          and r.term_cd = c.term_cd
          and r.course_cntl_num = c.course_cntl_num
      order by ldap_uid
      SQL
      result = connection.select_all(sql)
    }
    result
  end

  private

  def self.depts_clause
    string = if Settings.oec.departments.blank?
                ''
              else
                clause = 'and c.dept_name IN ('
                Settings.oec.departments.each_with_index do |dept, index|
                  clause.concat("'#{dept}'")
                  clause.concat(",") unless index == Settings.oec.departments.length - 1
                end
                clause.concat(')')
                clause
              end
    string
  end

end
