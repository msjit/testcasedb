class Ability
  include CanCan::Ability

  def initialize(user)
    # Notest on security in testcasedb
    # see config/locales/en.yaml for map of role integers to actual roles
    # All modules use the standard restful roles except for the test result
    # module.
    # Standard used restful roles
    #  - read, destroy, create, update  (and manage for all)
    # The TestResult module uses the following (with descrition)
    #  - read  (can see TestResults.. ie see asignments)
    #  - destroy (can delete TestResults.. assignments)
    #  - create (can create TestResults)
    #  - update (update TestResults)
    #  - manage (can do everything to TestResults including execute)
    #  - execute (can execute test cases)
    # 
    # 1: "Tester"
    # 2: "Senior Tester"
    # 3: "QA Manager"
    # 4: "Developer"
    # 10: "Admin"
    # 5: "API User"
    # If it is an admin
    if user.role == 10
      can :manage, :all
    # if it is a tester 
    elsif user.role == 1
      can [:create, :update, :read], TestCase
      can [:read, :execute], Assignment
      can [:read, :update, :execute], Result
      can [:create, :read, :update], TestPlan
      can [:create, :read, :update], Stencil
      can :read, Product
      can :read, Version
      can :manage, Step
      can [:read, :update, :create], Task
      can [:read, :update, :create], Schedule
      can :read, Device
    # If it is a senior tester
    elsif user.role == 2
      can :manage, TestCase
      can [:read, :execute, :create, :update], Result
      can [:read, :execute, :create, :update], Assignment
      can :manage, TestPlan
      can :manage, Stencil
      can :read, Product
      can :read, Tag
      can :read, Version
      can :manage, Report
      can :manage, Step
      can [:read, :create, :destroy], Upload
      can [:read, :update, :create], Task
      can :manage, Schedule
      can :read, Device
    # If it is a qa manager
    # Managers can essentially do anything but create users (that is left to admin)
    # Some customers may actually want to give QA managers the admin role
    elsif user.role == 3
      can :manage, [TestCase, Assignment, Result, TestPlan, Product, Version, TestType, Step, Stencil, Admin, Report, Task, Category, CustomField, Device, Upload, Schedule, Tag]
    # If it is a developer
    elsif user.role == 4
      can :read, TestCase
      can :read, TestPlan
      can :read, Stencil
      can :read, Assignment
      can :read, Result
      can :read, Step
      can [:read, :update, :create], Task
      can :read, Device
    # If it is an API user
    elsif user.role == 11
      can :manage, Webapi
    end
    
    # Everyone can create comments and uploads
    can [:create, :read], Comment
    can [:read, :create], Upload
    
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
