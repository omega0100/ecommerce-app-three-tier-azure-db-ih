import React, { useState, useEffect } from 'react';

export default function Group4ProjectPage() {
  const [scrollY, setScrollY] = useState(0);

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const members = [
    { 
      name: "Yousef", 
      role: "Team Lead", 
      color: "from-blue-500 via-cyan-500 to-teal-500", 
      icon: "👨‍💻", 
      description: "Leading the team with strategic vision and technical expertise in cloud architecture.",
      skills: ["Leadership", "Azure", "Strategy"]
    },
    { 
      name: "Abdullah111", 
      role: "DevOps Engineer", 
      color: "from-purple-500 via-pink-500 to-rose-500", 
      icon: "🚀", 
      description: "Building robust solutions with cutting-edge development practices and innovation.",
      skills: ["DevOps", "Automation", "CI/CD"]
    },
    { 
      name: "Danah", 
      role: "UI/UX Designer", 
      color: "from-emerald-500 via-green-500 to-teal-500", 
      icon: "🎨", 
      description: "Crafting beautiful user experiences with modern design principles and creativity.",
      skills: ["Design", "UX Research", "Prototyping"]
    }
  ];

  const projectFeatures = [
    { 
      title: "Cloud Integration", 
      icon: "☁️", 
      description: "Seamless Microsoft Azure integration with enterprise-grade scalable architecture",
      gradient: "from-blue-500 to-cyan-500"
    },
    { 
      title: "Automation", 
      icon: "⚡", 
      description: "Advanced automation using AI, ML, and intelligent systems for minimal human intervention",
      gradient: "from-purple-500 to-pink-500"
    },
    { 
      title: "Team Collaboration", 
      icon: "🤝", 
      description: "Agile methodologies with real-time collaboration and modern development practices",
      gradient: "from-emerald-500 to-teal-500"
    },
    { 
      title: "Performance", 
      icon: "🚀", 
      description: "Ultra-fast performance optimized for global scale with edge computing capabilities",
      gradient: "from-orange-500 to-red-500"
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900 relative overflow-hidden">
      
      {/* Animated Background Elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-gradient-to-br from-blue-400/20 to-purple-600/20 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-96 h-96 bg-gradient-to-br from-emerald-400/20 to-cyan-600/20 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-gradient-to-br from-pink-400/10 to-orange-600/10 rounded-full blur-3xl animate-pulse delay-2000"></div>
      </div>

      {/* Floating Particles */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        {[...Array(20)].map((_, i) => (
          <div
            key={i}
            className="absolute w-2 h-2 bg-white/20 rounded-full animate-pulse"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 3}s`,
              animationDuration: `${2 + Math.random() * 3}s`
            }}
          />
        ))}
      </div>

      {/* Hero Section */}
      <section className="min-h-screen flex items-center justify-center p-6 relative">
        <div className="max-w-7xl w-full">
          {/* Main Hero Card */}
          <div 
            className="bg-white/10 backdrop-blur-2xl rounded-[2rem] shadow-2xl border border-white/20 p-12 md:p-20 text-center transform hover:scale-105 transition-all duration-700 relative overflow-hidden"
            style={{
              transform: `translateY(${scrollY * 0.1}px)`,
            }}
          >
            
            {/* Animated Border */}
            <div className="absolute inset-0 rounded-[2rem] bg-gradient-to-r from-blue-500/50 via-purple-500/50 to-emerald-500/50 blur-sm animate-pulse"></div>
            <div className="absolute inset-[1px] rounded-[2rem] bg-white/10 backdrop-blur-2xl"></div>
            
            {/* Content */}
            <div className="relative z-10">
              {/* Floating Logo */}
              <div className="mb-16 relative">
                <div className="inline-flex items-center justify-center w-32 h-32 bg-gradient-to-br from-blue-500 via-purple-500 to-emerald-500 rounded-3xl shadow-2xl mb-8 transform rotate-12 hover:rotate-0 transition-all duration-500 animate-pulse">
                  <svg className="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                {/* Floating rings around logo */}
                <div className="absolute top-1/2 left-1/2 w-40 h-40 border-2 border-blue-400/30 rounded-full -translate-x-1/2 -translate-y-1/2 animate-spin"></div>
                <div className="absolute top-1/2 left-1/2 w-48 h-48 border border-purple-400/20 rounded-full -translate-x-1/2 -translate-y-1/2 animate-spin" style={{animationDirection: 'reverse', animationDuration: '8s'}}></div>
              </div>

              {/* Animated Title */}
              <h1 className="text-7xl md:text-8xl font-black mb-10 bg-gradient-to-r from-white via-blue-200 to-purple-200 bg-clip-text text-transparent animate-pulse leading-tight">
                Group 4
              </h1>
              <div className="text-4xl md:text-5xl font-bold mb-12 bg-gradient-to-r from-blue-400 via-purple-400 to-emerald-400 bg-clip-text text-transparent">
                Ironhack Project
              </div>
              
              {/* Enhanced Subtitle */}
              <div className="mb-16">
                <p className="text-2xl md:text-3xl text-white/90 font-light leading-relaxed max-w-5xl mx-auto mb-6">
                  Next-generation collaborative innovation powered by 
                  <span className="font-bold text-transparent bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text"> Microsoft Azure</span>
                </p>
                <p className="text-xl text-white/70 max-w-4xl mx-auto leading-relaxed">
                  A comprehensive showcase of modern development practices, cloud-native architecture, and exceptional teamwork in the digital age.
                </p>
              </div>

              {/* Glowing Team Preview */}
              <div className="mb-16">
                <h2 className="text-2xl text-white/80 uppercase tracking-wider font-medium mb-8">Our Team</h2>
                <div className="flex flex-wrap justify-center gap-6 mb-10">
                  {['Yousef', 'Abdullah', 'Danah'].map((name, index) => (
                    <div 
                      key={name}
                      className="group relative"
                      style={{animationDelay: `${index * 0.2}s`}}
                    >
                      <div className="absolute inset-0 bg-gradient-to-r from-blue-500 via-purple-500 to-emerald-500 rounded-2xl blur-lg group-hover:blur-xl transition-all duration-300 opacity-75"></div>
                      <div className="relative bg-white/10 backdrop-blur-xl text-white px-10 py-5 rounded-2xl font-bold text-lg shadow-2xl border border-white/20 hover:bg-white/20 transform hover:-translate-y-2 hover:scale-110 transition-all duration-500">
                        {name}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Premium Azure Badge */}
              <div className="inline-flex items-center gap-4 bg-gradient-to-r from-blue-500/20 to-indigo-500/20 backdrop-blur-xl px-10 py-6 rounded-2xl border border-white/30 hover:border-white/50 transition-all duration-500 mb-16 group">
                <div className="w-12 h-12 bg-gradient-to-br from-blue-400 to-indigo-500 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                  <svg className="w-7 h-7 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M5.5 3L9 6.5L18.5 3L22 6.5L18.5 21L5.5 21L2 6.5L5.5 3Z" />
                  </svg>
                </div>
                <span className="text-white font-bold text-xl">Powered by Microsoft Azure</span>
              </div>

              {/* Scroll Animation */}
              <div className="flex flex-col items-center">
                <p className="text-white/60 mb-6 text-lg">Discover our project</p>
                <div className="flex gap-3">
                  <div className="w-4 h-4 bg-gradient-to-r from-blue-400 to-cyan-400 rounded-full animate-bounce"></div>
                  <div className="w-4 h-4 bg-gradient-to-r from-purple-400 to-pink-400 rounded-full animate-bounce delay-100"></div>
                  <div className="w-4 h-4 bg-gradient-to-r from-emerald-400 to-teal-400 rounded-full animate-bounce delay-200"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Enhanced Project Features */}
      <section className="py-32 px-6 relative">
        <div className="max-w-8xl mx-auto">
          <div className="text-center mb-24">
            <div className="inline-block mb-8">
              <div className="bg-gradient-to-r from-blue-500 to-purple-500 text-white px-8 py-4 rounded-2xl text-sm font-bold uppercase tracking-wider shadow-2xl">
                Project Excellence
              </div>
            </div>
            <h2 className="text-6xl md:text-7xl font-black bg-gradient-to-r from-white via-blue-200 to-purple-200 bg-clip-text text-transparent mb-8">
              Our Work
            </h2>
            <p className="text-2xl text-white/80 max-w-4xl mx-auto leading-relaxed">
              A simple and practical implementation showcasing our effort in Azure.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-10">
            {projectFeatures.map((feature, index) => (
              <div 
                key={feature.title}
                className="group relative"
                style={{animationDelay: `${index * 0.2}s`}}
              >
                {/* Glowing Background */}
                <div className={`absolute inset-0 bg-gradient-to-br ${feature.gradient} rounded-3xl blur-lg group-hover:blur-xl transition-all duration-500 opacity-20 group-hover:opacity-30`}></div>
                
                {/* Card Content */}
                <div className="relative bg-white/10 backdrop-blur-2xl rounded-3xl p-8 shadow-2xl border border-white/20 hover:border-white/40 transform hover:-translate-y-4 hover:scale-105 transition-all duration-700 h-full">
                  <div className="text-6xl mb-6 filter drop-shadow-lg">{feature.icon}</div>
                  <h3 className="text-2xl font-bold text-white mb-4">{feature.title}</h3>
                  <p className="text-white/70 leading-relaxed">{feature.description}</p>
                  
                  {/* Hover Effect Bar */}
                  <div className={`absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r ${feature.gradient} rounded-b-3xl transform scale-x-0 group-hover:scale-x-100 transition-transform duration-500`}></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Premium Team Section */}
      <section className="py-32 px-6 relative">
        <div className="max-w-8xl mx-auto">
          
          {/* Team Header */}
          <div className="text-center mb-28">
            <div className="inline-block mb-8">
              <div className="bg-gradient-to-r from-emerald-500 to-teal-500 text-white px-8 py-4 rounded-2xl text-sm font-bold uppercase tracking-wider shadow-2xl">
                Meet the Visionaries
              </div>
            </div>
            
            <h2 className="text-6xl md:text-7xl font-black mb-10 bg-gradient-to-r from-white via-emerald-200 to-teal-200 bg-clip-text text-transparent">
              Our Team
            </h2>
            
            <p className="text-2xl text-white/80 max-w-5xl mx-auto leading-relaxed mb-12">
              Three extraordinary individuals united by passion, innovation, and an unwavering commitment to excellence in every aspect of our collaborative journey.
            </p>
            
            {/* Decorative Elements */}
            <div className="flex justify-center">
              <div className="w-40 h-1 bg-gradient-to-r from-emerald-500 via-teal-500 to-cyan-500 rounded-full"></div>
            </div>
          </div>

          {/* Team Cards Grid */}
          <div className="grid md:grid-cols-3 gap-12 mb-28">
            {members.map((member, index) => (
              <div 
                key={member.name} 
                className="group relative"
                style={{animationDelay: `${index * 0.3}s`}}
              >
                {/* Card Glow Effect */}
                <div className={`absolute inset-0 bg-gradient-to-br ${member.color} rounded-[2rem] blur-2xl group-hover:blur-3xl transition-all duration-700 opacity-20 group-hover:opacity-40`}></div>
                
                {/* Main Card */}
                <div className="relative bg-white/10 backdrop-blur-3xl rounded-[2rem] p-12 shadow-2xl border border-white/20 hover:border-white/40 transform hover:-translate-y-6 hover:scale-105 transition-all duration-700 h-full overflow-hidden">
                  
                  {/* Floating Decoration */}
                  <div className={`absolute -top-10 -right-10 w-32 h-32 bg-gradient-to-br ${member.color} rounded-full opacity-20 group-hover:scale-125 group-hover:opacity-30 transition-all duration-700`}></div>
                  
                  <div className="relative z-10 text-center">
                    {/* Avatar with Animation */}
                    <div className="mb-10">
                      <div className={`inline-flex items-center justify-center w-28 h-28 bg-gradient-to-br ${member.color} rounded-3xl shadow-2xl mb-8 text-5xl transform group-hover:rotate-12 group-hover:scale-110 transition-all duration-500`}>
                        {member.icon}
                      </div>
                    </div>

                    {/* Member Info */}
                    <h3 className="text-3xl font-black text-white mb-4 group-hover:text-transparent group-hover:bg-gradient-to-r group-hover:from-white group-hover:to-blue-200 group-hover:bg-clip-text transition-all duration-500">
                      {member.name}
                    </h3>
                    
                    <p className={`text-xl font-bold bg-gradient-to-r ${member.color} bg-clip-text text-transparent mb-6`}>
                      {member.role}
                    </p>
                    
                    <p className="text-white/70 leading-relaxed mb-8">
                      {member.description}
                    </p>

                    {/* Skills Pills */}
                    <div className="flex flex-wrap justify-center gap-2">
                      {member.skills.map((skill, skillIndex) => (
                        <span 
                          key={skill}
                          className={`px-4 py-2 bg-gradient-to-r ${member.color} rounded-full text-white text-sm font-semibold shadow-lg transform hover:scale-105 transition-all duration-300`}
                          style={{animationDelay: `${skillIndex * 0.1}s`}}
                        >
                          {skill}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Hover Glow */}
                  <div className={`absolute inset-0 rounded-[2rem] bg-gradient-to-br ${member.color} opacity-0 group-hover:opacity-10 transition-opacity duration-700`}></div>
                </div>
              </div>
            ))}
          </div>

          {/* Enhanced Stats Section */}
          <div className="bg-white/10 backdrop-blur-3xl rounded-[2rem] p-16 shadow-2xl border border-white/20 text-center relative overflow-hidden">
            {/* Background Pattern */}
            <div className="absolute inset-0 opacity-10">
              <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-blue-500/20 via-purple-500/20 to-emerald-500/20"></div>
            </div>
            
            <div className="relative z-10">
              <h3 className="text-4xl font-black text-white mb-12">Project Excellence Metrics</h3>
              <div className="grid md:grid-cols-4 gap-12">
                {[
                  { value: "3", label: "Elite Members", color: "text-blue-400", icon: "👥" },
                  { value: "1", label: "Shared Vision", color: "text-purple-400", icon: "🎯" },
                  { value: "∞", label: "Possibilities", color: "text-emerald-400", icon: "🚀" },
                  { value: "100%", label: "Commitment", color: "text-pink-400", icon: "💎" }
                ].map((stat, index) => (
                  <div key={stat.label} className="group">
                    <div className="text-6xl mb-2">{stat.icon}</div>
                    <div className={`text-5xl font-black ${stat.color} mb-3 group-hover:scale-110 transition-transform duration-300`}>
                      {stat.value}
                    </div>
                    <div className="text-white/70 font-semibold text-lg">{stat.label}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Epic Footer */}
      <section className="py-24 px-6 relative">
        <div className="max-w-6xl mx-auto text-center">
          <div className="bg-gradient-to-r from-blue-600 via-purple-600 to-emerald-600 text-white rounded-[2rem] p-16 shadow-2xl relative overflow-hidden">
            {/* Animated Background */}
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/50 via-purple-500/50 to-emerald-500/50 animate-pulse"></div>
            
            <div className="relative z-10">
              <h3 className="text-5xl font-black mb-6">Thank You</h3>
              <p className="text-2xl text-white/90 mb-12 max-w-4xl mx-auto leading-relaxed">
                This project embodies our unwavering dedication to innovation, collaboration, and excellence in the realm of cloud computing with Microsoft Azure. Together, we've created something truly extraordinary.
              </p>
              
              {/* Final Animation */}
              <div className="flex justify-center gap-6">
                <div className="w-6 h-6 bg-white/40 rounded-full animate-bounce"></div>
                <div className="w-6 h-6 bg-white/40 rounded-full animate-bounce delay-100"></div>
                <div className="w-6 h-6 bg-white/40 rounded-full animate-bounce delay-200"></div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
