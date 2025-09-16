# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.

# This file is part of Canvas.

# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.

# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.

# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../../common"
require_relative "../pages/course_page"
require_relative "../pages/student_context_tray_page"
require_relative "../../../factories/admin_analytics_tool_factory"

describe "analytics in Canvas" do
  include_context "in-process server selenium tests"
  include CourseHomePage
  include StudentContextTray
  include Factories

  context "Analytics 2.0 LTI installed" do
    before :once do
      @admin = account_admin_user(active_all: true)
      # Analytics1.0 is enabled for all tests by default
      @admin.account.update(allowed_services: "+analytics")
      # add the analytics 2 LTI to the account
      admin_analytics_tool_factory
      @tool_id = @admin.account.context_external_tools.first.id
      # create a course, @teacher and student in course
      @course = course_with_teacher(
        account: @admin.account,
        course_name: "A New Course",
        name: "Teacher1",
        active_all: true
      ).course
      @student = student_in_course(
        course: @course,
        name: "First Student",
        active_all: true
      ).user
    end

    describe "student context tray for teacher role" do
      context "with A2 FF enabled" do
        before do
          @course.root_account.enable_feature!(:analytics_2)
          user_session(@teacher)

          visit_course_people_page(@course.id)
          course_user_link(@student.id).click
          wait_for_student_tray
        end

        it "displays Admin Analytics button on Student Tray" do
          expect(student_tray_quick_links.text).to include("Admin Analytics")
        end
      end

      context "with A2 FF disabled" do
        before do
          @course.root_account.disable_feature!(:analytics_2)
          user_session(@teacher)

          visit_course_people_page(@course.id)
          course_user_link(@student.id).click
          wait_for_student_tray
        end

        it "does not displays Analytics 1 button on Student Tray" do
          expect(student_tray_quick_links.text).not_to include("Analytics")
          expect(student_tray_quick_links.text).not_to include("Admin Analytics")
        end
      end
    end
  end
end
