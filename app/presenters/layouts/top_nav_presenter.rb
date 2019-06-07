module Layouts
  class TopNavPresenter < ::ApplicationPresenter
    def school_name
      @school_name ||= current_school.present? ? current_school.name : 'PupilFirst'
    end

    def logo?
      return true if current_school.blank?

      current_school.logo_on_light_bg.attached?
    end

    def logo_url
      if current_school.blank?
        view.image_url('mailer/pupilfirst-logo.png')
      else
        view.url_for(current_school.logo_variant(:mid))
      end
    end

    def visible_links
      if nav_links.length > 4
        nav_links[0..2]
      else
        nav_links
      end
    end

    def more_links
      @more_links ||= begin
        if nav_links.length > 4
          {
            title: 'More',
            id: 'navbar-more-dropdown',
            options: nav_links[-(nav_links.length - 3)..-1]
          }
        end
      end
    end

    def selectable_student_profiles
      @selectable_student_profiles ||= begin
        if current_school.blank? || current_founder.blank?
          Founder.none
        else
          current_user.founders
            .not_exited
            .joins(:school).where(schools: { id: current_school })
        end
      end
    end

    private

    def nav_links
      @nav_links ||= begin
        # User-based links...
        links = [admin_link, review_link, dashboard_link, leaderboard_link] - [nil]

        # ...and the custom links.
        custom_links = SchoolLink.where(school: current_school, kind: SchoolLink::KIND_HEADER).order(created_at: :DESC).map do |school_link|
          { title: school_link.title, url: school_link.url }
        end

        # Both, with the user-based links at the front.
        links + custom_links
      end
    end

    def admin_link
      { title: 'Admin', url: '/school' } if current_school.present? && view.policy(current_school).show?
    end

    def review_link
      courses = current_coach&.courses_with_dashboard

      return if current_coach.blank? || courses.blank?

      title = -'Review Submissions'

      if courses.count == 1
        { title: title, url: view.course_coach_dashboard_path(courses.first) }
      else
        {
          title: title,
          id: 'navbar-review-dropdown',
          options: courses.map { |c| { title: c.name, url: view.course_coach_dashboard_path(c) } }
        }
      end
    end

    def dashboard_link
      return if current_founder.blank? || current_founder.exited?

      if selectable_student_profiles.load.count > 1
        {
          title: 'Student Dashboard',
          id: 'navbar-student-dropdown',
          options: selectable_student_profiles.map do |sp|
            { title: "#{sp.course.name} Course", url: view.select_founder_path(sp), method: :post }
          end
        }
      else
        { title: 'Student Dashboard', url: view.student_dashboard_path }
      end
    end

    def leaderboard_link
      return if current_founder.blank? || current_founder.exited?

      lts = LeaderboardTimeService.new
      course = current_founder.course

      course_entries_last_week = LeaderboardEntry.joins(:course).where(
        courses: { id: course },
        period_from: lts.week_start,
        period_to: lts.week_end
      )

      if course_entries_last_week.exists?
        { title: 'Leaderboard', url: view.leaderboard_course_path(course) }
      end
    end
  end
end